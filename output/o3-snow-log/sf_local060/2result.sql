WITH US_CUSTOMERS AS (                -- all U.S. customers
    SELECT  c."cust_id",
            c."cust_city"
    FROM    COMPLEX_ORACLE.COMPLEX_ORACLE."CUSTOMERS"       c
    JOIN    COMPLEX_ORACLE.COMPLEX_ORACLE."COUNTRIES"       ct
           ON c."country_id" = ct."country_id"
    WHERE   ct."country_iso_code" = 'US' 
            OR ct."country_name"  = 'United States of America'
), -----------------------------------------------------------------
CITY_QTR_SALES AS (                  -- Q4-sales (no promo) per city
    SELECT  uc."cust_city",
            t."calendar_year"  AS year,
            SUM(s."amount_sold") AS sales
    FROM    COMPLEX_ORACLE.COMPLEX_ORACLE."SALES"  s
    JOIN    US_CUSTOMERS                              uc ON s."cust_id" = uc."cust_id"
    JOIN    COMPLEX_ORACLE.COMPLEX_ORACLE."TIMES"     t  ON s."time_id" = t."time_id"
    WHERE   t."calendar_year"         IN (2019,2020)
      AND   t."calendar_quarter_number" = 4              -- Q4
      AND   s."promo_id"                = 999            -- no promotion
    GROUP BY uc."cust_city", t."calendar_year"
), -----------------------------------------------------------------
GROWING_CITIES AS (                 -- cities whose Q4 sales ↑ ≥20 %
    SELECT  c19."cust_city"
    FROM    CITY_QTR_SALES  c19
    JOIN    CITY_QTR_SALES  c20
           ON c19."cust_city" = c20."cust_city"
    WHERE   c19.year = 2019
      AND   c20.year = 2020
      AND   c20.sales >= c19.sales * 1.20
), -----------------------------------------------------------------
CITY_SALES AS (                     -- sales in those cities, Q4 19/20
    SELECT  s."prod_id",
            t."calendar_year" AS year,
            SUM(s."amount_sold") AS sales
    FROM    COMPLEX_ORACLE.COMPLEX_ORACLE."SALES"  s
    JOIN    US_CUSTOMERS                              uc ON s."cust_id" = uc."cust_id"
    JOIN    COMPLEX_ORACLE.COMPLEX_ORACLE."TIMES"     t  ON s."time_id" = t."time_id"
    WHERE   t."calendar_year"         IN (2019,2020)
      AND   t."calendar_quarter_number" = 4
      AND   s."promo_id"                = 999
      AND   uc."cust_city"              IN (SELECT "cust_city" FROM GROWING_CITIES)
    GROUP BY s."prod_id", t."calendar_year"
), -----------------------------------------------------------------
TOTAL_SALES_BY_YEAR AS (            -- totals for share calc
    SELECT  year,
            SUM(sales) AS total_sales
    FROM    CITY_SALES
    GROUP BY year
), -----------------------------------------------------------------
PROD_TOTAL AS (                     -- total (19+20) per product for ranking
    SELECT  "prod_id",
            SUM(sales) AS total_sales
    FROM    CITY_SALES
    GROUP BY "prod_id"
), -----------------------------------------------------------------
RANKED AS (                         -- top-20 % products
    SELECT  "prod_id",
            total_sales,
            PERCENT_RANK() OVER (ORDER BY total_sales DESC) AS pr
    FROM    PROD_TOTAL
), -----------------------------------------------------------------
TOP_PRODUCTS AS (
    SELECT  "prod_id"
    FROM    RANKED
    WHERE   pr <= 0.20
), -----------------------------------------------------------------
PRODUCT_SHARE AS (                  -- product share in each year
    SELECT  cs."prod_id",
            cs.year,
            cs.sales / ts.total_sales  AS share
    FROM    CITY_SALES            cs
    JOIN    TOTAL_SALES_BY_YEAR   ts ON cs.year = ts.year
    WHERE   cs."prod_id" IN (SELECT "prod_id" FROM TOP_PRODUCTS)
), -----------------------------------------------------------------
PIVOTED AS (                        -- shares side-by-side
    SELECT  "prod_id",
            COALESCE(MAX(CASE WHEN year = 2019 THEN share END), 0) AS share_2019,
            COALESCE(MAX(CASE WHEN year = 2020 THEN share END), 0) AS share_2020
    FROM    PRODUCT_SHARE
    GROUP BY "prod_id"
), -----------------------------------------------------------------
FINAL AS (
    SELECT  p."prod_id",
            p."prod_name",
            share_2019,
            share_2020,
            (share_2020 - share_2019) AS share_change
    FROM    PIVOTED                                 pv
    JOIN    COMPLEX_ORACLE.COMPLEX_ORACLE."PRODUCTS" p  ON pv."prod_id" = p."prod_id"
)
SELECT  *
FROM    FINAL
ORDER BY share_change DESC NULLS LAST;