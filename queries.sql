/* ============================================================
   Olist Retail SQL Analysis (PostgreSQL)
   File: queries.sql
   Purpose: Portfolio-ready KPI and insight queries
   ============================================================ */

-- ------------------------------------------------------------
-- 00) Sanity checks (dataset size)
-- ------------------------------------------------------------
SELECT COUNT(*) AS customers_rows FROM customers;
SELECT COUNT(*) AS orders_rows FROM orders;
SELECT COUNT(*) AS products_rows FROM products;
SELECT COUNT(*) AS order_items_rows FROM order_items;
SELECT COUNT(*) AS order_payments_rows FROM order_payments;

-- ------------------------------------------------------------
-- 01) Core KPIs: orders, customers, items/order
-- ------------------------------------------------------------
SELECT
  (SELECT COUNT(*) FROM orders)            AS total_orders,
  (SELECT COUNT(*) FROM customers)         AS total_customers,
  (SELECT COUNT(*) FROM order_items)       AS total_order_items,
  ROUND(
    (SELECT COUNT(*) FROM order_items)::numeric
    / NULLIF((SELECT COUNT(*) FROM orders), 0),
    3
  ) AS avg_items_per_order;

-- ------------------------------------------------------------
-- 02) Total revenue (items only)
-- Note: price = item revenue (excludes freight)
-- ------------------------------------------------------------
SELECT
  ROUND(SUM(price), 2) AS total_revenue
FROM order_items;

-- ------------------------------------------------------------
-- 03) Average Order Value (AOV)
-- ------------------------------------------------------------
SELECT
  ROUND(
    SUM(oi.price) / COUNT(DISTINCT o.order_id),
    2
  ) AS avg_order_value
FROM orders o
JOIN order_items oi
  ON o.order_id = oi.order_id;

-- ------------------------------------------------------------
-- 04) Monthly revenue trend
-- Important: early/late months may be partial (validate coverage)
-- ------------------------------------------------------------
SELECT
  DATE_TRUNC('month', o.order_purchase_timestamp) AS month,
  ROUND(SUM(oi.price), 2) AS monthly_revenue
FROM orders o
JOIN order_items oi
  ON o.order_id = oi.order_id
GROUP BY 1
ORDER BY 1;

-- ------------------------------------------------------------
-- 05) Revenue by product category
-- ------------------------------------------------------------
SELECT
  p.product_category_name AS category,
  ROUND(SUM(oi.price), 2) AS total_revenue
FROM order_items oi
JOIN products p
  ON oi.product_id = p.product_id
GROUP BY p.product_category_name
ORDER BY total_revenue DESC;

-- ------------------------------------------------------------
-- 06) Payment mix: revenue + transaction counts by payment type
-- Note: payment_value includes the total paid (often includes freight)
-- ------------------------------------------------------------
SELECT
  payment_type,
  ROUND(SUM(payment_value), 2) AS total_payment_value,
  COUNT(*) AS payment_count
FROM order_payments
GROUP BY payment_type
ORDER BY total_payment_value DESC;

-- ------------------------------------------------------------
-- 07) Credit card installment behavior
-- ------------------------------------------------------------
SELECT
  payment_installments,
  COUNT(*) AS transactions,
  ROUND(SUM(payment_value), 2) AS total_value
FROM order_payments
WHERE payment_type = 'credit_card'
GROUP BY payment_installments
ORDER BY payment_installments;
