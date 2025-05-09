WITH
-- Total sales per city in Q4 2019 (excluding promotions)
sales_2019 AS (
    SELECT c."cust_city", SUM(s."amount_sold") AS total_sales_2019
    FROM COMPLEX_ORACLE.COMPLEX_ORACLE."SALES" s
    JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."CUSTOMERS" c ON s."cust_id" = c."cust_id"
    JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."COUNTRIES" co ON c."country_id" = co."country_id"
    WHERE s."promo_id" = 999
      AND TO_DATE(s."time_id", 'YYYY-MM-DD') BETWEEN '2019-10-01' AND '2019-12-31'
      AND co."country_name" = 'United States of America'
    GROUP BY c."cust_city"
),
-- Total sales per city in Q4 2020 (excluding promotions)
sales_2020 AS (
    SELECT c."cust_city", SUM(s."amount_sold") AS total_sales_2020
    FROM COMPLEX_ORACLE.COMPLEX_ORACLE."SALES" s
    JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."CUSTOMERS" c ON s."cust_id" = c."cust_id"
    JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."COUNTRIES" co ON c."country_id" = co."country_id"
    WHERE s."promo_id" = 999
      AND TO_DATE(s."time_id", 'YYYY-MM-DD') BETWEEN '2020-10-01' AND '2020-12-31'
      AND co."country_name" = 'United States of America'
    GROUP BY c."cust_city"
),
-- Calculate growth rate per city and select cities with at least 20% increase
selected_cities AS (
    SELECT s19."cust_city" AS city
    FROM sales_2019 s19
    JOIN sales_2020 s20 ON s19."cust_city" = s20."cust_city"
    WHERE s19.total_sales_2019 > 0
      AND ((s20.total_sales_2020 - s19.total_sales_2019) / s19.total_sales_2019) >= 0.20
),
-- Total sales per product per year in selected cities (excluding promotions)
product_sales AS (
    SELECT s."prod_id", p."prod_name",
           EXTRACT(YEAR FROM TO_DATE(s."time_id", 'YYYY-MM-DD')) AS year,
           SUM(s."quantity_sold") AS total_quantity,
           SUM(s."amount_sold") AS total_sales
    FROM COMPLEX_ORACLE.COMPLEX_ORACLE."SALES" s
    JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."CUSTOMERS" c ON s."cust_id" = c."cust_id"
    JOIN selected_cities sc ON c."cust_city" = sc.city
    JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."COUNTRIES" co ON c."country_id" = co."country_id"
    JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."PRODUCTS" p ON s."prod_id" = p."prod_id"
    WHERE s."promo_id" = 999
      AND TO_DATE(s."time_id", 'YYYY-MM-DD') BETWEEN '2019-10-01' AND '2020-12-31'
      AND co."country_name" = 'United States of America'
    GROUP BY s."prod_id", p."prod_name", year
),
-- Calculate total sales per product across both years
product_total_sales AS (
    SELECT "prod_id", "prod_name", SUM(total_sales) AS total_sales
    FROM product_sales
    GROUP BY "prod_id", "prod_name"
),
-- Rank products and select top 20%
ranked_products AS (
    SELECT *,
           NTILE(5) OVER (ORDER BY total_sales DESC) AS ntile
    FROM product_total_sales
),
top_products AS (
    SELECT "prod_id", "prod_name"
    FROM ranked_products
    WHERE ntile = 1
),
-- Total sales per year in selected cities (excluding promotions)
total_sales_per_year AS (
    SELECT EXTRACT(YEAR FROM TO_DATE(s."time_id", 'YYYY-MM-DD')) AS year,
           SUM(s."amount_sold") AS total_sales_year
    FROM COMPLEX_ORACLE.COMPLEX_ORACLE."SALES" s
    JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."CUSTOMERS" c ON s."cust_id" = c."cust_id"
    JOIN selected_cities sc ON c."cust_city" = sc.city
    JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."COUNTRIES" co ON c."country_id" = co."country_id"
    WHERE s."promo_id" = 999
      AND TO_DATE(s."time_id", 'YYYY-MM-DD') BETWEEN '2019-10-01' AND '2020-12-31'
      AND co."country_name" = 'United States of America'
    GROUP BY year
),
-- Calculate share of total sales per product per year
product_share AS (
    SELECT ps."prod_id", ps."prod_name", ps.year, ps.total_sales,
           ts.total_sales_year,
           (ps.total_sales / ts.total_sales_year) * 100 AS share_percentage
    FROM product_sales ps
    JOIN top_products tp ON ps."prod_id" = tp."prod_id"
    JOIN total_sales_per_year ts ON ps.year = ts.year
),
-- Pivot the data to have shares for both years side by side
product_share_pivot AS (
    SELECT "prod_id", "prod_name",
           MAX(CASE WHEN year = 2019 THEN share_percentage END) AS Share_Q4_2019,
           MAX(CASE WHEN year = 2020 THEN share_percentage END) AS Share_Q4_2020
    FROM product_share
    GROUP BY "prod_id", "prod_name"
)
-- Final selection with share change calculation
SELECT
    "prod_id" AS Product_ID,
    "prod_name" AS Product_Name,
    ROUND(NVL(Share_Q4_2019, 0), 4) AS Share_Q4_2019,
    ROUND(NVL(Share_Q4_2020, 0), 4) AS Share_Q4_2020,
    ROUND(NVL(Share_Q4_2020, 0) - NVL(Share_Q4_2019, 0), 4) AS Share_Change
FROM product_share_pivot
ORDER BY Share_Change DESC NULLS LAST;