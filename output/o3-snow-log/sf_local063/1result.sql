/*--------------------------------------------------------------
  Product in U.S. growth-cities (≥20 % promo-999 sales gain
  from Q4-2019 → Q4-2020) that sits in the top-20 % of combined
  sales and shows the smallest percentage-point change in share
  of total sales between the two quarters.
--------------------------------------------------------------*/
WITH us_country AS (
    SELECT "country_id"
    FROM   COMPLEX_ORACLE.COMPLEX_ORACLE.COUNTRIES
    WHERE  "country_name" ILIKE '%United%States%'
    LIMIT  1
),  /* ─────────────────────────────────────────────────────── */
q_sales AS (                  -- promo-999 sales in the two quarters
    SELECT c."cust_city",
           s."prod_id",
           s."amount_sold",
           t."calendar_quarter_id"
    FROM   COMPLEX_ORACLE.COMPLEX_ORACLE.SALES     s
    JOIN   COMPLEX_ORACLE.COMPLEX_ORACLE.TIMES     t ON t."time_id"  = s."time_id"
    JOIN   COMPLEX_ORACLE.COMPLEX_ORACLE.CUSTOMERS c ON c."cust_id"  = s."cust_id"
    WHERE  s."promo_id" = 999
      AND  t."calendar_quarter_id" IN (1772,1776)              -- Q4-2019 / Q4-2020
      AND  c."country_id" = (SELECT "country_id" FROM us_country)
),  /* ─────────────────────────────────────────────────────── */
city_totals AS (              -- city-level totals per quarter
    SELECT "cust_city",
           SUM(CASE WHEN "calendar_quarter_id" = 1772 THEN "amount_sold" END) AS sales_2019,
           SUM(CASE WHEN "calendar_quarter_id" = 1776 THEN "amount_sold" END) AS sales_2020
    FROM   q_sales
    GROUP  BY "cust_city"
),  /* ─────────────────────────────────────────────────────── */
growth_cities AS (            -- cities with ≥20 % growth
    SELECT "cust_city"
    FROM   city_totals
    WHERE  sales_2019 > 0
      AND  sales_2020 >= sales_2019 * 1.20
),  /* ─────────────────────────────────────────────────────── */
prod_totals AS (              -- product totals within growth-cities
    SELECT s."prod_id",
           SUM(CASE WHEN t."calendar_quarter_id" = 1772 THEN s."amount_sold" ELSE 0 END) AS sales_2019,
           SUM(CASE WHEN t."calendar_quarter_id" = 1776 THEN s."amount_sold" ELSE 0 END) AS sales_2020
    FROM   COMPLEX_ORACLE.COMPLEX_ORACLE.SALES     s
    JOIN   COMPLEX_ORACLE.COMPLEX_ORACLE.TIMES     t ON t."time_id" = s."time_id"
    JOIN   COMPLEX_ORACLE.COMPLEX_ORACLE.CUSTOMERS c ON c."cust_id" = s."cust_id"
    WHERE  s."promo_id" = 999
      AND  t."calendar_quarter_id" IN (1772,1776)
      AND  c."cust_city" IN (SELECT "cust_city" FROM growth_cities)
    GROUP  BY s."prod_id"
),  /* ─────────────────────────────────────────────────────── */
totals AS (                   -- grand totals for share calculation
    SELECT SUM(sales_2019) AS total_2019,
           SUM(sales_2020) AS total_2020
    FROM   prod_totals
),  /* ─────────────────────────────────────────────────────── */
shares AS (                   -- per-product shares and change
    SELECT p."prod_id",
           p.sales_2019,
           p.sales_2020,
           (p.sales_2019 + p.sales_2020)                                         AS combined_sales,
           p.sales_2019 / NULLIF(t.total_2019,0)                                 AS share_2019,
           p.sales_2020 / NULLIF(t.total_2020,0)                                 AS share_2020,
           (p.sales_2020 / NULLIF(t.total_2020,0)) 
         - (p.sales_2019 / NULLIF(t.total_2019,0))                               AS share_change
    FROM   prod_totals p
    CROSS  JOIN totals t
),  /* ─────────────────────────────────────────────────────── */
ranked AS (                   -- top-20 % bucket & absolute change
    SELECT *,
           NTILE(5) OVER (ORDER BY combined_sales DESC)                          AS sales_bucket,
           ABS(share_change)                                                     AS abs_change
    FROM   shares
)
SELECT  "prod_id",
        sales_2019,
        sales_2020,
        share_2019,
        share_2020,
        share_change
FROM    ranked
WHERE   sales_bucket = 1                         -- top 20 % of sales
ORDER BY abs_change ASC, "prod_id"
LIMIT   1;                                        -- smallest share swing