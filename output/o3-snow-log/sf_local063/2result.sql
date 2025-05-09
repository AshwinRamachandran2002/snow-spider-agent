WITH us_country AS (                            -- United States country_id
    SELECT "country_id"
    FROM   COMPLEX_ORACLE.COMPLEX_ORACLE.COUNTRIES
    WHERE  "country_name" = 'United States of America'
),

/*-------------------------------------------------------------------
  Base rows: only U.S. promo-999 sales for the two quarters of interest
-------------------------------------------------------------------*/
sales_base AS (
    SELECT s."amount_sold",
           s."prod_id",
           c."cust_city",
           t."calendar_quarter_id"
    FROM   COMPLEX_ORACLE.COMPLEX_ORACLE.SALES    s
           JOIN COMPLEX_ORACLE.COMPLEX_ORACLE.TIMES     t ON s."time_id" = t."time_id"
           JOIN COMPLEX_ORACLE.COMPLEX_ORACLE.CUSTOMERS c ON s."cust_id" = c."cust_id"
    WHERE  s."promo_id" = 999
      AND  t."calendar_quarter_id" IN (1772,1776)     -- 2019-Q4 & 2020-Q4
      AND  c."country_id" IN (SELECT "country_id" FROM us_country)
),

/*-------------------------------------------------------------------
  City-level totals per quarter, then keep only the cities whose
  sales grew ≥ 20 % from 2019-Q4 to 2020-Q4
-------------------------------------------------------------------*/
city_qtr AS (
    SELECT "cust_city",
           "calendar_quarter_id",
           SUM("amount_sold") AS city_sales
    FROM   sales_base
    GROUP  BY "cust_city","calendar_quarter_id"
),
growth_cities AS (
    SELECT a."cust_city"
    FROM   city_qtr a
           JOIN city_qtr b
                 ON a."cust_city"            = b."cust_city"
                AND a."calendar_quarter_id"  = 1772      -- 2019-Q4
                AND b."calendar_quarter_id"  = 1776      -- 2020-Q4
    WHERE  (b.city_sales - a.city_sales) / a.city_sales >= 0.20
),

/*-------------------------------------------------------------------
  Promo-999 sales restricted to the growth cities
-------------------------------------------------------------------*/
filtered_sales AS (
    SELECT sb.*
    FROM   sales_base sb
           JOIN growth_cities gc ON sb."cust_city" = gc."cust_city"
),

/*-------------------------------------------------------------------
  Product-level and quarter-level aggregates + total-sales denominator
-------------------------------------------------------------------*/
prod_qtr AS (
    SELECT "prod_id",
           "calendar_quarter_id",
           SUM("amount_sold") AS prod_sales
    FROM   filtered_sales
    GROUP  BY "prod_id","calendar_quarter_id"
),
tot_qtr AS (
    SELECT "calendar_quarter_id",
           SUM("amount_sold") AS tot_sales
    FROM   filtered_sales
    GROUP  BY "calendar_quarter_id"
),

/*-------------------------------------------------------------------
  Share of each product in each quarter; treat missing quarter as 0
-------------------------------------------------------------------*/
prod_share AS (
    SELECT pq."prod_id",
           COALESCE(MAX(CASE WHEN pq."calendar_quarter_id" = 1772 
                             THEN pq.prod_sales END),0)  AS sales_2019_q4,
           COALESCE(MAX(CASE WHEN pq."calendar_quarter_id" = 1776 
                             THEN pq.prod_sales END),0)  AS sales_2020_q4,
           COALESCE(MAX(CASE WHEN pq."calendar_quarter_id" = 1772 
                             THEN pq.prod_sales END),0) /
           (SELECT tot_sales FROM tot_qtr WHERE "calendar_quarter_id" = 1772)  AS share_2019_q4,
           COALESCE(MAX(CASE WHEN pq."calendar_quarter_id" = 1776 
                             THEN pq.prod_sales END),0) /
           (SELECT tot_sales FROM tot_qtr WHERE "calendar_quarter_id" = 1776)  AS share_2020_q4
    FROM   prod_qtr pq
    GROUP  BY pq."prod_id"
),

/*-------------------------------------------------------------------
  Rank products by combined two-quarter sales
-------------------------------------------------------------------*/
ranked AS (
    SELECT ps.*,
           (ps.sales_2019_q4 + ps.sales_2020_q4) AS two_qtr_total
    FROM   prod_share ps
),

/*-------------------------------------------------------------------
  Keep only the top 20 % (highest two-quarter totals)
-------------------------------------------------------------------*/
top_20pct AS (
    SELECT *
    FROM   ranked
    QUALIFY NTILE(5) OVER (ORDER BY two_qtr_total DESC) = 1
),

/*-------------------------------------------------------------------
  Compute share change and pick the product with the smallest
  absolute percentage-point change
-------------------------------------------------------------------*/
final AS (
    SELECT "prod_id",
           share_2019_q4,
           share_2020_q4,
           share_2020_q4 - share_2019_q4  AS share_change
    FROM   top_20pct
)
SELECT *
FROM   final
ORDER  BY ABS(share_change) ASC NULLS LAST
LIMIT 1;