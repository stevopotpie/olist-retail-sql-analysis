/* ============================================================
   Load the Olist CSVs into the schema (run with psql)
   Run from the folder that holds the Kaggle CSV files:
     cd path/to/olist_csvs
     psql -d olist_retail -f path/to/schema.sql
     psql -d olist_retail -f path/to/load.sql
   ============================================================ */

\set ON_ERROR_STOP on

\copy customers FROM 'olist_customers_dataset.csv' WITH (FORMAT csv, HEADER true)
\copy sellers FROM 'olist_sellers_dataset.csv' WITH (FORMAT csv, HEADER true)
\copy orders FROM 'olist_orders_dataset.csv' WITH (FORMAT csv, HEADER true)
\copy category_translation FROM 'product_category_name_translation.csv' WITH (FORMAT csv, HEADER true)
\copy products FROM 'olist_products_dataset.csv' WITH (FORMAT csv, HEADER true)
\copy order_items FROM 'olist_order_items_dataset.csv' WITH (FORMAT csv, HEADER true)
\copy order_payments FROM 'olist_order_payments_dataset.csv' WITH (FORMAT csv, HEADER true)
\copy order_reviews FROM 'olist_order_reviews_dataset.csv' WITH (FORMAT csv, HEADER true)

ANALYZE;
