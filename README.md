# Olist Retail Analytics (PostgreSQL)

## Project Overview
This project analyzes transactional data from **Olist**, a Brazilian e-commerce marketplace, using **PostgreSQL**.  
The goal is to derive business insights related to revenue performance, customer purchasing behavior, product mix, and payment methods through structured SQL analysis.

The dataset represents a real-world, multi-table retail schema and was analyzed with a focus on **data integrity, reproducibility, and business interpretation** rather than surface-level metrics.

---

## Tools & Technologies
- **Database:** PostgreSQL  
- **Querying:** SQL (joins, aggregations, windowed time analysis)  
- **Environment:** pgAdmin  
- **Version Control:** Git / GitHub  

---

## Dataset Description
The dataset consists of multiple related CSV files representing customers, orders, products, payments, and order items.

### Core Tables
- `customers` — customer demographics and location  
- `orders` — order lifecycle timestamps and status  
- `products` — product attributes and categories  
- `order_items` — item-level pricing and quantities  
- `order_payments` — payment methods and installment details  

> **Note:**  
> The full dataset exceeds GitHub’s file-size limits and is not included in this repository.  
> To reproduce the analysis, download the original Olist dataset and place the CSV files in a local directory before importing them into PostgreSQL.

---

## Key KPIs & Insights

### 1. Core Marketplace Metrics
- **Total Orders:** 99,441  
- **Total Customers:** 99,441  
- **Total Order Items:** 112,650  
- **Average Items per Order:** 1.133  

**Insight:**  
Most customers purchase a single item per order, indicating limited bundling behavior and a focus on individual product purchases.

---

### 2. Revenue Performance
- **Total Product Revenue:** \$13.59M  
- **Average Order Value (AOV):** \$137.75  

**Insight:**  
The marketplace operates with a mid-range AOV, suggesting customers primarily purchase moderately priced goods rather than low-cost, high-volume items.

---

### 3. Revenue Trends Over Time
Monthly revenue analysis shows:

- **Late 2016:** Extremely low and inconsistent revenue, indicating a platform ramp-up or pilot phase  
- **2017–2018:** Rapid growth followed by stabilization, with monthly revenue averaging **\$850k–\$1.0M**
- **Late 2018:** Sharp drop due to partial-month data rather than business decline  

**Analytical Takeaway:**  
Temporal completeness must be validated before interpreting trends. Early and late outliers reflect dataset coverage limitations, not operational performance.

---

### 4. Revenue by Product Category
- Revenue is distributed across **74 product categories**
- Top categories include:
  - Health & Beauty
  - Watches & Gifts
  - Home & Bath
  - Sports & Leisure
  - Tech Accessories

**Insight:**  
No single category dominates revenue, indicating a **diversified long-tail marketplace**. Growth is driven by category breadth rather than reliance on a narrow product segment.

---

### 5. Payment Method Behavior
- **Credit Cards:** ~\$12.5M revenue (dominant method)
- **Boleto:** ~\$2.9M revenue (significant secondary method)
- **Debit Cards & Vouchers:** Minor share

**Insight:**  
While credit cards dominate, boleto usage highlights the importance of alternative payment methods in the Brazilian market and supports broader customer accessibility.

---

### 6. Credit Card Installment Analysis
- **Single-payment purchases** are most common
- **2–6 installments** represent the core financed purchase range
- **8–10 installments**, while less frequent, are associated with higher transaction values

**Analytical Takeaway:**  
Installment flexibility plays a key role in enabling higher-value purchases, aligning with the platform’s mid-range AOV and diverse product mix.

---

## Key SQL Queries
All queries used to generate KPIs and insights are saved in **`queries.sql`**, including:

- Dataset sanity checks (row counts)
- Core KPIs (orders, customers, avg items/order)
- Total revenue and AOV
- Monthly revenue trends
- Revenue by product category
- Payment method mix
- Credit card installment behavior

### How to Run
1. Open **pgAdmin**
2. Connect to the `olist_retail` database
3. Open `queries.sql` in the Query Tool
4. Run individual sections as needed

### Database Setup
- `schema.sql` contains the table definitions used in this analysis
- `queries.sql` contains all KPI and analytical queries
---

## Skills Demonstrated
- Relational data modeling and schema design  
- Multi-table joins and aggregations  
- KPI-driven SQL analysis  
- Time-series validation and anomaly detection  
- Translating raw metrics into business insights  
- Troubleshooting real-world data and tooling issues 

---

## Notes on Analysis Approach
This project emphasizes analytical decision-making in addition to SQL execution.  
Special attention was given to validating data completeness, identifying partial or anomalous records, and avoiding misleading conclusions when interpreting trends.

---

