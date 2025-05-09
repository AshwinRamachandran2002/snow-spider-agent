WITH US_CUSTOMERS AS  (   -- U.S. customers
    SELECT cu."cust_id",
           cu."cust_city"
    FROM   COMPLEX_ORACLE.COMPLEX_ORACLE.CUSTOMERS  cu
    JOIN   COMPLEX_ORACLE.COMPLEX_ORACLE.COUNTRIES  co
           ON cu."country_id" = co."country_id"
    WHERE  co."country_iso_code" = 'US'
       OR  UPPER(co."country_name") LIKE 'UNITED STATES%'    
),  
SALES_US_NP AS (          -- U.S. sales in Q4-2019 / Q4-2020, no promotion (promo_id = 999)
    SELECT s."prod_id",
           uc."cust_city",
           t."calendar_year",
           t."calendar_quarter_number",
           s."amount_sold"
    FROM   COMPLEX_ORACLE.COMPLEX_ORACLE.SALES   s
    JOIN   US_CUSTOMERS                          uc ON s."cust_id" = uc."cust_id"
    JOIN   COMPLEX_ORACLE.COMPLEX_ORACLE.TIMES   t  ON s."time_id"  = t."time_id"
    WHERE  s."promo_id" = 999
      AND  t."calendar_quarter_number" = 4
      AND  t."calendar_year" IN (2019,2020)
),  
CITY_QUARTER_SALES AS (   -- city totals per quarter
    SELECT "cust_city"      AS city,
           "calendar_year",
           SUM("amount_sold") AS city_sales
    FROM   SALES_US_NP
    GROUP  BY "cust_city","calendar_year"
),  
CITY_GROWTH AS (          -- cities whose sales grew ≥20 %
    SELECT c19.city,
           c19.city_sales AS sales_2019,
           c20.city_sales AS sales_2020
    FROM   CITY_QUARTER_SALES c19
    JOIN   CITY_QUARTER_SALES c20
           ON c19.city = c20.city
    WHERE  c19."calendar_year" = 2019
      AND  c20."calendar_year" = 2020
      AND  c19.city_sales  > 0
      AND  c20.city_sales >= c19.city_sales * 1.2
),  
PRODUCT_TOTAL_SALES AS (  -- product totals in the growing cities (both quarters)
    SELECT s."prod_id",
           SUM(s."amount_sold") AS total_sales
    FROM   SALES_US_NP s
    JOIN   CITY_GROWTH cg ON s."cust_city" = cg.city
    GROUP  BY s."prod_id"
),  
RANKED_PRODUCTS AS (      -- rank & count for 20 % cut-off
    SELECT pt."prod_id",
           pt.total_sales,
           ROW_NUMBER() OVER(ORDER BY pt.total_sales DESC) AS rn,
           COUNT(*)   OVER()                                AS cnt
    FROM   PRODUCT_TOTAL_SALES pt
),  
TOP_PRODUCTS AS (         -- keep top 20 %
    SELECT "prod_id"
    FROM   RANKED_PRODUCTS
    WHERE  rn <= CEIL(cnt * 0.20)
),  
PRODUCT_SALES_Q AS (      -- product sales per quarter (selected cities, top products)
    SELECT s."prod_id",
           SUM(CASE WHEN s."calendar_year" = 2019 THEN s."amount_sold" END) AS sales_2019,
           SUM(CASE WHEN s."calendar_year" = 2020 THEN s."amount_sold" END) AS sales_2020
    FROM   SALES_US_NP s
    JOIN   CITY_GROWTH cg ON s."cust_city" = cg.city
    WHERE  s."prod_id" IN (SELECT "prod_id" FROM TOP_PRODUCTS)
    GROUP  BY s."prod_id"
),  
TOTAL_SALES_Q AS (        -- grand totals (selected cities)
    SELECT SUM(CASE WHEN "calendar_year" = 2019 THEN "amount_sold" END) AS total_2019,
           SUM(CASE WHEN "calendar_year" = 2020 THEN "amount_sold" END) AS total_2020
    FROM   SALES_US_NP s
    JOIN   CITY_GROWTH cg ON s."cust_city" = cg.city
)
SELECT ps."prod_id",
       pr."prod_name",
       ps.sales_2019,
       ps.sales_2020,
       ROUND( COALESCE(ps.sales_2019,0) / ts.total_2019 , 4) AS share_2019,
       ROUND( COALESCE(ps.sales_2020,0) / ts.total_2020 , 4) AS share_2020,
       ROUND( COALESCE(ps.sales_2020,0) / ts.total_2020
            - COALESCE(ps.sales_2019,0) / ts.total_2019 , 4) AS share_change
FROM   PRODUCT_SALES_Q          ps
JOIN   COMPLEX_ORACLE.COMPLEX_ORACLE.PRODUCTS pr
       ON ps."prod_id" = pr."prod_id"
CROSS  JOIN TOTAL_SALES_Q       ts
ORDER  BY share_change DESC NULLS LAST;