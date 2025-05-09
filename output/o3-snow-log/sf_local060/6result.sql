/*----------------------------------------------------------
Pull U.S. sales with NO promotions (promo_id = 999) that fall
in calendar Q4 of 2019 or 2020, keep only the cities whose
total Q4 sales grew ≥20 %, pick the top-20 % products in those
cities (by combined Q4 sales), then calculate each selected
product’s share of total Q4 sales in the two years and the
change in share.
----------------------------------------------------------*/
WITH base_sales AS (   -- all Q4-2019 / Q4-2020 U.S. sales without promos
    SELECT
        c."cust_city"                         AS city,
        s."prod_id"                           AS prod_id,
        s."amount_sold"                       AS amount_sold,
        t."calendar_year"                     AS year
    FROM "COMPLEX_ORACLE"."COMPLEX_ORACLE"."SALES"      s
    JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."TIMES"      t
          ON s."time_id" = t."time_id"
    JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."CUSTOMERS"  c
          ON s."cust_id" = c."cust_id"
    JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."COUNTRIES"  cn
          ON c."country_id" = cn."country_id"
    WHERE cn."country_iso_code"        = 'US'          -- United States
      AND s."promo_id"                 = 999           -- no promotion
      AND t."calendar_quarter_number"  = 4             -- Q4
      AND t."calendar_year"            IN (2019,2020)
),
city_year_sales AS (   -- Q4 totals by city & year
    SELECT city,
           year,
           SUM(amount_sold) AS city_year_amt
    FROM   base_sales
    GROUP  BY city, year
),
city_growth AS (       -- cities whose Q4 sales rose ≥20 % from ’19→’20
    SELECT city,
           MAX(CASE WHEN year=2019 THEN city_year_amt END) AS amt_2019,
           MAX(CASE WHEN year=2020 THEN city_year_amt END) AS amt_2020
    FROM   city_year_sales
    GROUP  BY city
    HAVING MAX(CASE WHEN year=2019 THEN city_year_amt END) > 0
       AND MAX(CASE WHEN year=2020 THEN city_year_amt END)
           >= 1.2 * MAX(CASE WHEN year=2019 THEN city_year_amt END)
),
selected_sales AS (    -- restrict sales to those fast-growing cities
    SELECT bs.*
    FROM   base_sales bs
    JOIN   city_growth cg  ON bs.city = cg.city
),
product_combined AS (  -- combined (’19+’20) sales per product
    SELECT  prod_id,
            SUM(amount_sold) AS total_amt
    FROM    selected_sales
    GROUP   BY prod_id
),
top_products AS (      -- keep top 20 % by using PERCENT_RANK ≤0.2
    SELECT  prod_id,
            total_amt,
            PERCENT_RANK() OVER (ORDER BY total_amt DESC) AS pr
    FROM    product_combined
    QUALIFY pr <= 0.2
),
product_year_sales AS (    -- yearly totals for the top products
    SELECT ss.prod_id,
           ss.year,
           SUM(ss.amount_sold) AS prod_year_amt
    FROM   selected_sales ss
    JOIN   top_products  tp  ON ss.prod_id = tp.prod_id
    GROUP  BY ss.prod_id, ss.year
),
total_year_sales AS (      -- overall Q4 totals (all products) in sel. cities
    SELECT year,
           SUM(amount_sold) AS year_total_amt
    FROM   selected_sales
    GROUP  BY year
),
shares AS (                -- product share per year
    SELECT pys.prod_id,
           pys.year,
           pys.prod_year_amt / tys.year_total_amt AS share
    FROM   product_year_sales pys
    JOIN   total_year_sales  tys
           ON pys.year = tys.year
),
pivot_shares AS (          -- turn rows into columns
    SELECT prod_id,
           MAX(CASE WHEN year=2019 THEN share END) AS share_2019,
           MAX(CASE WHEN year=2020 THEN share END) AS share_2020
    FROM   shares
    GROUP  BY prod_id
),
result AS (                -- add product name & compute change
    SELECT ps.prod_id,
           COALESCE(p."prod_name",'Unknown')                             AS prod_name,
           ROUND(COALESCE(ps.share_2019,0),4)                           AS share_2019,
           ROUND(COALESCE(ps.share_2020,0),4)                           AS share_2020,
           ROUND(COALESCE(ps.share_2020,0) - COALESCE(ps.share_2019,0),4) AS share_change
    FROM   pivot_shares ps
    LEFT  JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."PRODUCTS" p
           ON ps.prod_id = p."prod_id"
)
SELECT *
FROM   result
ORDER  BY share_change DESC NULLS LAST;