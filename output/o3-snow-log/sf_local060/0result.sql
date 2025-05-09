/*--------------------------------------------------------
Step-by-step
  1. Pull U.S. sales with NO promotions (promo_id = 999)
     for calendar Q4 of 2019 and 2020.
  2. Keep only those cities whose Q4-2020 sales are
     at least 20 % larger than their Q4-2019 sales.
  3. Inside those cities, rank products by their combined
     (2019 Q4 + 2020 Q4) sales and keep the top 20 %.
  4. For every kept product, compute its share of total
     sales (same city set, still no promos) in Q4-2019
     and Q4-2020 and the change in share.
--------------------------------------------------------*/
WITH sales_us_qtr AS (   -- all U.S. sales, no promotions, Q4-2019/2020
    SELECT
        s."cust_id",
        s."prod_id",
        s."time_id",
        s."amount_sold",
        t."calendar_year",
        t."calendar_quarter_number",
        c."cust_city"
    FROM "COMPLEX_ORACLE"."COMPLEX_ORACLE"."SALES"      s
    JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."CUSTOMERS"  c
           ON s."cust_id" = c."cust_id"
    JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."COUNTRIES"  co
           ON c."country_id" = co."country_id"
    JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."TIMES"      t
           ON s."time_id" = t."time_id"
    WHERE co."country_iso_code"        = 'US'
      AND s."promo_id"                 = 999          -- no promotion
      AND t."calendar_quarter_number"  = 4            -- Q4
      AND t."calendar_year"           IN (2019,2020)
),
/*------------------------------------------------------*/
city_sales AS (          -- total Q4 sales per city per year
    SELECT
        "cust_city"            AS city,
        "calendar_year"        AS year,
        SUM("amount_sold")     AS city_sales
    FROM sales_us_qtr
    GROUP BY "cust_city", "calendar_year"
),
/*------------------------------------------------------*/
increase_cities AS (     -- cities whose Q4-2020 ≥ 120 % of Q4-2019
    SELECT c19.city
    FROM  city_sales c19
    JOIN  city_sales c20
          ON c19.city = c20.city
         AND c19.year = 2019
         AND c20.year = 2020
    WHERE c20.city_sales >= c19.city_sales * 1.20
),
/*------------------------------------------------------*/
filtered_sales AS (      -- keep only those cities
    SELECT fs.*
    FROM   sales_us_qtr  fs
    JOIN   increase_cities ic
           ON fs."cust_city" = ic.city
),
/*------------------------------------------------------*/
prod_totals AS (         -- combined Q4-2019+2020 sales per product
    SELECT
        "prod_id",
        SUM("amount_sold") AS total_sales
    FROM filtered_sales
    GROUP BY "prod_id"
),
product_rank AS (        -- divide into 5 equal tiles, pick top tile
    SELECT
        "prod_id",
        total_sales,
        NTILE(5) OVER (ORDER BY total_sales DESC) AS ntl
    FROM prod_totals
),
top_products AS (
    SELECT "prod_id"
    FROM   product_rank
    WHERE  ntl = 1                          -- top 20 %
),
/*------------------------------------------------------*/
prod_year_sales AS (     -- yearly sales for the kept products
    SELECT
        fs."prod_id",
        fs."calendar_year"      AS year,
        SUM(fs."amount_sold")   AS sales
    FROM   filtered_sales fs
    JOIN   top_products  tp
           ON fs."prod_id" = tp."prod_id"
    GROUP BY fs."prod_id", fs."calendar_year"
),
year_totals AS (         -- total sales (all products) per year
    SELECT
        "calendar_year" AS year,
        SUM("amount_sold") AS total_sales
    FROM filtered_sales
    GROUP BY "calendar_year"
),
prod_shares AS (         -- share = product / yearly total
    SELECT
        pys."prod_id",
        pys.year,
        pys.sales,
        pys.sales / yt.total_sales  AS share
    FROM prod_year_sales pys
    JOIN year_totals     yt
          ON pys.year = yt.year
),
/*------------------------------------------------------*/
prod_share_change AS (   -- pivot to 2019 vs 2020 + share difference
    SELECT
        ps19."prod_id",
        ps19.share  AS share_2019,
        ps20.share  AS share_2020,
        ps20.share - ps19.share AS share_change
    FROM prod_shares ps19
    JOIN prod_shares ps20
          ON ps19."prod_id" = ps20."prod_id"
         AND ps19.year = 2019
         AND ps20.year = 2020
)
/*==============  Final result  ========================*/
SELECT
    psc."prod_id",
    pr."prod_name",
    ROUND(psc.share_2019,4) AS share_2019,
    ROUND(psc.share_2020,4) AS share_2020,
    ROUND(psc.share_change,4) AS share_change
FROM   prod_share_change                         psc
LEFT   JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."PRODUCTS" pr
           ON psc."prod_id" = pr."prod_id"
ORDER  BY share_change DESC NULLS LAST;