/* ============================================================
   Olist Retail SQL Analysis (PostgreSQL)
   File: queries.sql
   Every number in the README comes from a query in this file.
   Revenue = item price, excluding freight, for DELIVERED orders
   unless a query says otherwise.
   ============================================================ */

-- ------------------------------------------------------------
-- 00) Data checks
-- ------------------------------------------------------------

-- Row counts
SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM customers
UNION ALL SELECT 'sellers',        COUNT(*) FROM sellers
UNION ALL SELECT 'orders',         COUNT(*) FROM orders
UNION ALL SELECT 'products',       COUNT(*) FROM products
UNION ALL SELECT 'order_items',    COUNT(*) FROM order_items
UNION ALL SELECT 'order_payments', COUNT(*) FROM order_payments
UNION ALL SELECT 'order_reviews',  COUNT(*) FROM order_reviews;

-- The customers table has one row per ORDER. Count people with customer_unique_id.
SELECT
  COUNT(*)                           AS customer_rows,
  COUNT(DISTINCT customer_unique_id) AS unique_customers
FROM customers;

-- Order status mix and the item revenue attached to each status
SELECT
  o.order_status,
  COUNT(DISTINCT o.order_id)    AS orders,
  ROUND(COALESCE(SUM(oi.price), 0), 2) AS item_revenue
FROM orders o
LEFT JOIN order_items oi ON oi.order_id = o.order_id
GROUP BY o.order_status
ORDER BY orders DESC;

-- Orders with no items (canceled or never fulfilled)
SELECT COUNT(*) AS orders_without_items
FROM orders o
WHERE NOT EXISTS (SELECT 1 FROM order_items oi WHERE oi.order_id = o.order_id);

-- Months with very few orders are coverage gaps, not business results
SELECT
  DATE_TRUNC('month', order_purchase_timestamp)::date AS month,
  COUNT(*) AS orders
FROM orders
GROUP BY 1
HAVING COUNT(*) < 500
ORDER BY 1;

-- ------------------------------------------------------------
-- 01) Core KPIs (delivered orders)
-- ------------------------------------------------------------
SELECT
  COUNT(DISTINCT o.order_id)                       AS delivered_orders,
  COUNT(DISTINCT c.customer_unique_id)             AS customers,
  COUNT(*)                                         AS items,
  ROUND(COUNT(*)::numeric / COUNT(DISTINCT o.order_id), 3) AS items_per_order,
  ROUND(SUM(oi.price), 2)                          AS revenue,
  ROUND(SUM(oi.price) / COUNT(DISTINCT o.order_id), 2)     AS avg_order_value
FROM orders o
JOIN customers   c  ON c.customer_id = o.customer_id
JOIN order_items oi ON oi.order_id   = o.order_id
WHERE o.order_status = 'delivered';

-- ------------------------------------------------------------
-- 02) Repeat customers
-- ------------------------------------------------------------
WITH per_person AS (
  SELECT c.customer_unique_id, COUNT(*) AS orders
  FROM orders o
  JOIN customers c ON c.customer_id = o.customer_id
  WHERE o.order_status = 'delivered'
  GROUP BY c.customer_unique_id
)
SELECT
  COUNT(*)                                   AS customers,
  COUNT(*) FILTER (WHERE orders > 1)         AS repeat_customers,
  ROUND(AVG((orders > 1)::int) * 100, 1)     AS repeat_rate_pct
FROM per_person;

-- ------------------------------------------------------------
-- 03) Monthly revenue with month over month growth (window functions)
-- Full months only: Jan 2017 to Aug 2018
-- ------------------------------------------------------------
WITH monthly AS (
  SELECT
    DATE_TRUNC('month', o.order_purchase_timestamp)::date AS month,
    COUNT(DISTINCT o.order_id) AS orders,
    SUM(oi.price)              AS revenue
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  WHERE o.order_status = 'delivered'
    AND o.order_purchase_timestamp >= '2017-01-01'
    AND o.order_purchase_timestamp <  '2018-09-01'
  GROUP BY 1
)
SELECT
  month,
  orders,
  ROUND(revenue, 0) AS revenue,
  ROUND((revenue / LAG(revenue) OVER (ORDER BY month) - 1) * 100, 1) AS mom_growth_pct,
  ROUND(SUM(revenue) OVER (ORDER BY month), 0)                       AS running_revenue
FROM monthly
ORDER BY month;

-- ------------------------------------------------------------
-- 04) Revenue by category, in English, with share and cumulative share
-- ------------------------------------------------------------
WITH by_category AS (
  SELECT
    COALESCE(t.product_category_name_english, p.product_category_name, 'unknown') AS category,
    SUM(oi.price) AS revenue
  FROM order_items oi
  JOIN orders   o ON o.order_id   = oi.order_id
  JOIN products p ON p.product_id = oi.product_id
  LEFT JOIN category_translation t ON t.product_category_name = p.product_category_name
  WHERE o.order_status = 'delivered'
  GROUP BY 1
)
SELECT
  RANK() OVER (ORDER BY revenue DESC)                                       AS rank,
  category,
  ROUND(revenue, 0)                                                         AS revenue,
  ROUND(revenue / SUM(revenue) OVER () * 100, 1)                            AS share_pct,
  ROUND(SUM(revenue) OVER (ORDER BY revenue DESC) / SUM(revenue) OVER () * 100, 1) AS cumulative_pct
FROM by_category
ORDER BY revenue DESC;

-- ------------------------------------------------------------
-- 05) Seller concentration: how many sellers make 80% of revenue?
-- ------------------------------------------------------------
WITH by_seller AS (
  SELECT oi.seller_id, SUM(oi.price) AS revenue
  FROM order_items oi
  JOIN orders o ON o.order_id = oi.order_id
  WHERE o.order_status = 'delivered'
  GROUP BY oi.seller_id
),
ranked AS (
  SELECT
    revenue,
    ROW_NUMBER() OVER (ORDER BY revenue DESC)  AS seller_rank,
    SUM(revenue) OVER (ORDER BY revenue DESC)  AS running_revenue,
    SUM(revenue) OVER ()                       AS total_revenue,
    COUNT(*)     OVER ()                       AS sellers
  FROM by_seller
)
SELECT
  MAX(sellers)                                               AS sellers,
  MIN(seller_rank) FILTER (WHERE running_revenue >= 0.8 * total_revenue) AS sellers_for_80_pct,
  ROUND(MIN(seller_rank) FILTER (WHERE running_revenue >= 0.8 * total_revenue)::numeric
        / MAX(sellers) * 100, 1)                             AS pct_of_sellers
FROM ranked;

-- ------------------------------------------------------------
-- 06) Payment mix
-- Note: payment_value is the total paid, including freight
-- ------------------------------------------------------------
SELECT
  payment_type,
  COUNT(*)                                                    AS payments,
  ROUND(SUM(payment_value), 2)                                AS total_paid,
  ROUND(SUM(payment_value) / SUM(SUM(payment_value)) OVER () * 100, 1) AS share_pct
FROM order_payments
GROUP BY payment_type
ORDER BY total_paid DESC;

-- ------------------------------------------------------------
-- 07) Credit card installments vs purchase size
-- ------------------------------------------------------------
SELECT
  CASE
    WHEN payment_installments <= 1 THEN '1 payment'
    WHEN payment_installments <= 6 THEN '2 to 6'
    ELSE '7 or more'
  END                                AS installments,
  COUNT(*)                           AS payments,
  ROUND(AVG(payment_value), 2)       AS avg_payment
FROM order_payments
WHERE payment_type = 'credit_card'
GROUP BY 1
ORDER BY MIN(payment_installments);

-- ------------------------------------------------------------
-- 08) Delivery performance: actual vs promised
-- ------------------------------------------------------------
SELECT
  COUNT(*) AS delivered_orders,
  ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY
        EXTRACT(EPOCH FROM order_delivered_customer_date - order_purchase_timestamp) / 86400)::numeric, 1)
                                                                  AS median_days_to_deliver,
  ROUND(AVG(EXTRACT(EPOCH FROM order_estimated_delivery_date - order_purchase_timestamp) / 86400)::numeric, 1)
                                                                  AS avg_days_promised,
  ROUND(AVG((order_delivered_customer_date::date > order_estimated_delivery_date::date)::int) * 100, 1)
                                                                  AS late_pct
FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL;

-- ------------------------------------------------------------
-- 09) Late deliveries vs review scores
-- ------------------------------------------------------------
WITH delivery AS (
  SELECT
    order_id,
    order_delivered_customer_date::date - order_estimated_delivery_date::date AS days_late
  FROM orders
  WHERE order_status = 'delivered'
    AND order_delivered_customer_date IS NOT NULL
),
review AS (
  SELECT order_id, AVG(review_score) AS score
  FROM order_reviews
  GROUP BY order_id
)
SELECT
  CASE
    WHEN d.days_late <= 0 THEN '1. On time or early'
    WHEN d.days_late <= 7 THEN '2. 1 to 7 days late'
    ELSE                       '3. 8+ days late'
  END                                    AS delivery,
  COUNT(*)                               AS orders,
  ROUND(AVG(r.score), 2)                 AS avg_review,
  ROUND(AVG((r.score <= 2)::int) * 100, 1) AS pct_1_or_2_stars
FROM delivery d
JOIN review r ON r.order_id = d.order_id
GROUP BY 1
ORDER BY 1;

-- ------------------------------------------------------------
-- 10) Late rate by month (where did delivery break down?)
-- ------------------------------------------------------------
SELECT
  DATE_TRUNC('month', order_purchase_timestamp)::date AS month,
  COUNT(*) AS delivered_orders,
  ROUND(AVG((order_delivered_customer_date::date > order_estimated_delivery_date::date)::int) * 100, 1) AS late_pct
FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL
  AND order_purchase_timestamp >= '2017-01-01'
  AND order_purchase_timestamp <  '2018-09-01'
GROUP BY 1
ORDER BY 1;

-- ------------------------------------------------------------
-- 11) Delivery time by customer state
-- ------------------------------------------------------------
SELECT
  c.customer_state,
  COUNT(*) AS delivered_orders,
  ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY
        EXTRACT(EPOCH FROM o.order_delivered_customer_date - o.order_purchase_timestamp) / 86400)::numeric, 1)
                                                         AS median_days,
  ROUND(AVG((o.order_delivered_customer_date::date > o.order_estimated_delivery_date::date)::int) * 100, 1)
                                                         AS late_pct
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY c.customer_state
ORDER BY delivered_orders DESC;
