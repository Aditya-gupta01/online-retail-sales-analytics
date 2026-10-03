-- ============================================================
-- ONLINE RETAIL SALES ANALYTICS
-- SQL QUERIES
-- ============================================================


-- ============================================================
-- 1. BRONZE LAYER - RAW DATA
-- ============================================================

-- Raw dataset:
-- Online Retail II - Year 2009-2010
-- Raw table: retail_2009_2010

SELECT *
FROM retail_2009_2010
LIMIT 10;


-- Bronze Layer Data Profiling

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT Invoice) AS total_invoices,
    COUNT(DISTINCT Customer_ID) AS total_customers,
    COUNT(DISTINCT StockCode) AS total_products
FROM retail_2009_2010;


-- Raw Revenue Check

SELECT
    ROUND(SUM(Quantity * Price), 2) AS total_revenue
FROM retail_2009_2010
WHERE Quantity > 0
  AND Price > 0;


-- ============================================================
-- 2. SILVER LAYER - DATA CLEANING
-- ============================================================

DROP TABLE IF EXISTS silver_retail_sales;

CREATE TABLE silver_retail_sales AS
SELECT
    TRIM(Invoice) AS Invoice,
    TRIM(StockCode) AS StockCode,
    TRIM(Description) AS Description,
    Quantity,
    InvoiceDate,
    Price,
    Customer_ID,
    TRIM(Country) AS Country,
    ROUND(Quantity * Price, 2) AS Revenue
FROM retail_2009_2010
WHERE Quantity > 0
  AND Price > 0
  AND Description IS NOT NULL
  AND TRIM(Description) <> ''
  AND Country IS NOT NULL
  AND TRIM(Country) <> '';


-- Silver Layer Validation

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT Invoice) AS total_orders,
    COUNT(DISTINCT Customer_ID) AS total_customers,
    COUNT(DISTINCT StockCode) AS total_products
FROM silver_retail_sales;


-- ============================================================
-- 3. GOLD LAYER - MONTHLY SALES
-- ============================================================

DROP TABLE IF EXISTS gold_monthly_sales;

CREATE TABLE gold_monthly_sales AS
SELECT
    SUBSTR(InvoiceDate, 1, 7) AS month,
    COUNT(DISTINCT Invoice) AS orders,
    COUNT(DISTINCT Customer_ID) AS customers,
    ROUND(SUM(Quantity), 0) AS units_sold,
    ROUND(SUM(Revenue), 2) AS revenue
FROM silver_retail_sales
GROUP BY SUBSTR(InvoiceDate, 1, 7)
ORDER BY month;


-- ============================================================
-- 4. GOLD LAYER - COUNTRY SALES
-- ============================================================

DROP TABLE IF EXISTS gold_country_sales;

CREATE TABLE gold_country_sales AS
SELECT
    Country,
    COUNT(DISTINCT Invoice) AS orders,
    COUNT(DISTINCT Customer_ID) AS customers,
    ROUND(SUM(Quantity), 0) AS units_sold,
    ROUND(SUM(Revenue), 2) AS revenue
FROM silver_retail_sales
GROUP BY Country
ORDER BY revenue DESC;


-- ============================================================
-- 5. GOLD LAYER - PRODUCT SALES
-- ============================================================

DROP TABLE IF EXISTS gold_product_sales;

CREATE TABLE gold_product_sales AS
SELECT
    StockCode,
    Description,
    COUNT(DISTINCT Invoice) AS orders,
    ROUND(SUM(Quantity), 0) AS units_sold,
    ROUND(SUM(Revenue), 2) AS revenue
FROM silver_retail_sales
GROUP BY StockCode, Description
ORDER BY revenue DESC;


-- ============================================================
-- 6. GOLD LAYER - CUSTOMER SALES
-- ============================================================

DROP TABLE IF EXISTS gold_customer_sales;

CREATE TABLE gold_customer_sales AS
SELECT
    Customer_ID,
    COUNT(DISTINCT Invoice) AS orders,
    COUNT(DISTINCT StockCode) AS products_bought,
    ROUND(SUM(Quantity), 0) AS units_sold,
    ROUND(SUM(Revenue), 2) AS revenue
FROM silver_retail_sales
WHERE Customer_ID IS NOT NULL
GROUP BY Customer_ID
ORDER BY revenue DESC;


-- ============================================================
-- 7. KPI ANALYSIS
-- ============================================================

SELECT
    ROUND(SUM(Revenue), 2) AS total_revenue,
    COUNT(DISTINCT Invoice) AS total_orders,
    COUNT(DISTINCT Customer_ID) AS total_customers,
    COUNT(DISTINCT StockCode) AS total_products,
    ROUND(SUM(Quantity), 0) AS total_units_sold,
    ROUND(
        SUM(Revenue) / COUNT(DISTINCT Invoice),
        2
    ) AS average_order_value
FROM silver_retail_sales;


-- ============================================================
-- 8. MONTHLY REVENUE TREND
-- ============================================================

SELECT
    SUBSTR(InvoiceDate, 1, 7) AS month,
    ROUND(SUM(Revenue), 2) AS revenue
FROM silver_retail_sales
GROUP BY SUBSTR(InvoiceDate, 1, 7)
ORDER BY month;


-- ============================================================
-- 9. COUNTRY-WISE REVENUE
-- ============================================================

SELECT
    Country,
    ROUND(SUM(Revenue), 2) AS revenue
FROM silver_retail_sales
GROUP BY Country
ORDER BY revenue DESC
LIMIT 10;


-- ============================================================
-- 10. TOP 10 CUSTOMERS
-- ============================================================

SELECT
    Customer_ID,
    ROUND(SUM(Revenue), 2) AS revenue,
    ROUND(SUM(Quantity), 0) AS units_sold
FROM silver_retail_sales
WHERE Customer_ID IS NOT NULL
GROUP BY Customer_ID
ORDER BY revenue DESC
LIMIT 10;


-- ============================================================
-- 11. TOP 10 PRODUCTS
-- ============================================================

SELECT
    Description,
    ROUND(SUM(Revenue), 2) AS revenue,
    ROUND(SUM(Quantity), 0) AS units_sold
FROM silver_retail_sales
WHERE Description IS NOT NULL
GROUP BY Description
ORDER BY revenue DESC
LIMIT 10;


-- ============================================================
-- 12. COUNTRY PERFORMANCE ANALYSIS
-- ============================================================

SELECT
    Country,
    ROUND(SUM(Revenue), 2) AS revenue,
    ROUND(SUM(Quantity), 0) AS units_sold
FROM silver_retail_sales
WHERE Country IS NOT NULL
GROUP BY Country
ORDER BY revenue DESC
LIMIT 10;


-- ============================================================
-- 13. AVERAGE ORDER VALUE
-- ============================================================

SELECT
    ROUND(SUM(Revenue), 2) AS total_revenue,
    COUNT(DISTINCT Invoice) AS total_orders,
    ROUND(
        SUM(Revenue) / COUNT(DISTINCT Invoice),
        2
    ) AS average_order_value
FROM silver_retail_sales;


-- ============================================================
-- 14. CUSTOMER REVENUE ANALYSIS
-- ============================================================

SELECT
    Customer_ID,
    ROUND(SUM(Revenue), 2) AS revenue
FROM silver_retail_sales
WHERE Customer_ID IS NOT NULL
GROUP BY Customer_ID
ORDER BY revenue DESC
LIMIT 10;


-- ============================================================
-- 15. MONTH-ON-MONTH REVENUE GROWTH
-- ============================================================

WITH monthly AS (
    SELECT
        SUBSTR(InvoiceDate, 1, 7) AS month,
        ROUND(SUM(Revenue), 2) AS revenue
    FROM silver_retail_sales
    GROUP BY SUBSTR(InvoiceDate, 1, 7)
)

SELECT
    month,
    revenue,
    ROUND(
        (revenue - LAG(revenue) OVER (ORDER BY month))
        * 100.0
        / NULLIF(
            LAG(revenue) OVER (ORDER BY month),
            0
        ),
        2
    ) AS mom_growth_percent
FROM monthly
ORDER BY month;


-- ============================================================
-- END OF SQL ANALYTICS PROJECT
-- ============================================================