/* Product (promo_id = 999) whose share of total sales changed the least (p.p.)
   between Q4-2019 (1772) and Q4-2020 (1776) in U.S. cities that grew ≥20 %        */

WITH us_country AS (                       -- United States country_id
    SELECT "country_id" AS us_country_id
    FROM   COMPLEX_ORACLE.COMPLEX_ORACLE.COUNTRIES
    WHERE  "country_name" ILIKE '%United%States%'
    LIMIT  1
),
city_qtr_sales AS (                        -- sales per city & quarter
    SELECT c."cust_city",
           t."calendar_quarter_id",
           SUM(s."amount_sold") AS city_qtr_sales
    FROM   COMPLEX_ORACLE.COMPLEX_ORACLE.SALES      s
    JOIN   COMPLEX_ORACLE.COMPLEX_ORACLE.CUSTOMERS  c ON s."cust_id" = c."cust_id"
    JOIN   COMPLEX_ORACLE.COMPLEX_ORACLE.TIMES      t ON s."time_id" = t."time_id"
    WHERE  s."promo_id" = 999
      AND  t."calendar_quarter_id" IN (1772,1776)      -- Q4-2019 & Q4-2020
      AND  c."country_id" = (SELECT us_country_id FROM us_country)
    GROUP  BY c."cust_city", t."calendar_quarter_id"
),
growth_cities AS (                         -- cities with ≥20 % growth
    SELECT a."cust_city"
    FROM   city_qtr_sales a
           JOIN city_qtr_sales b
             ON a."cust_city"           = b."cust_city"
            AND a."calendar_quarter_id" = 1772
            AND b."calendar_quarter_id" = 1776
    WHERE  a.city_qtr_sales > 0
      AND  (b.city_qtr_sales - a.city_qtr_sales) / a.city_qtr_sales >= 0.20
),
top_products AS (                          -- top-20 % products by sales
    SELECT s."prod_id",
           SUM(s."amount_sold") AS total_sales,
           PERCENT_RANK() OVER (ORDER BY SUM(s."amount_sold") DESC) AS pct_rnk
    FROM   COMPLEX_ORACLE.COMPLEX_ORACLE.SALES      s
    JOIN   COMPLEX_ORACLE.COMPLEX_ORACLE.CUSTOMERS  c ON s."cust_id" = c."cust_id"
    JOIN   COMPLEX_ORACLE.COMPLEX_ORACLE.TIMES      t ON s."time_id" = t."time_id"
    WHERE  s."promo_id" = 999
      AND  t."calendar_quarter_id" IN (1772,1776)
      AND  c."cust_city" IN (SELECT "cust_city" FROM growth_cities)
    GROUP  BY s."prod_id"
    QUALIFY pct_rnk <= 0.20
),
share_by_qtr AS (                          -- product share inside each quarter
    SELECT t."calendar_quarter_id",
           s."prod_id",
           SUM(s."amount_sold") AS prod_qtr_sales,
           SUM(SUM(s."amount_sold")) OVER (PARTITION BY t."calendar_quarter_id") AS total_qtr_sales
    FROM   COMPLEX_ORACLE.COMPLEX_ORACLE.SALES      s
    JOIN   COMPLEX_ORACLE.COMPLEX_ORACLE.CUSTOMERS  c ON s."cust_id" = c."cust_id"
    JOIN   COMPLEX_ORACLE.COMPLEX_ORACLE.TIMES      t ON s."time_id" = t."time_id"
    WHERE  s."promo_id" = 999
      AND  t."calendar_quarter_id" IN (1772,1776)
      AND  c."cust_city" IN (SELECT "cust_city" FROM growth_cities)
      AND  s."prod_id"   IN (SELECT "prod_id" FROM top_products)
    GROUP  BY t."calendar_quarter_id", s."prod_id"
),
pp_change AS (                             -- percentage-point change
    SELECT a."prod_id",
           (a.prod_qtr_sales / NULLIF(a.total_qtr_sales,0)) * 100 AS share_2019Q4,
           (b.prod_qtr_sales / NULLIF(b.total_qtr_sales,0)) * 100 AS share_2020Q4,
           ((b.prod_qtr_sales / NULLIF(b.total_qtr_sales,0)) * 100) -
           ((a.prod_qtr_sales / NULLIF(a.total_qtr_sales,0)) * 100)   AS pp_change
    FROM   share_by_qtr a
           JOIN share_by_qtr b
             ON a."prod_id"            = b."prod_id"
            AND a."calendar_quarter_id" = 1772
            AND b."calendar_quarter_id" = 1776
)
SELECT "prod_id",
       ROUND(share_2019Q4,2) AS share_2019Q4,
       ROUND(share_2020Q4,2) AS share_2020Q4,
       ROUND(pp_change,2)    AS pp_change
FROM   pp_change
ORDER  BY ABS(pp_change) ASC NULLS LAST, "prod_id"
LIMIT  1;