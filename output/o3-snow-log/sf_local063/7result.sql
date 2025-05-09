WITH us_sales AS (   -- U.S. promo-999 sales rows
    SELECT s."cust_id",
           s."prod_id",
           s."amount_sold",
           s."time_id",
           cu."cust_city"
    FROM   COMPLEX_ORACLE.COMPLEX_ORACLE."SALES"      s
    JOIN   COMPLEX_ORACLE.COMPLEX_ORACLE."CUSTOMERS"  cu ON s."cust_id" = cu."cust_id"
    JOIN   COMPLEX_ORACLE.COMPLEX_ORACLE."COUNTRIES"  ct ON cu."country_id" = ct."country_id"
    WHERE  ct."country_name" ILIKE '%United%States%'
      AND  s."promo_id" = 999
),
city_qtr AS (        -- city-level totals for Q4-2019 (1772) and Q4-2020 (1776)
    SELECT us."cust_city"          AS "city",
           t."calendar_quarter_id" AS "qtr",
           SUM(us."amount_sold")   AS "city_sales"
    FROM   us_sales                       us
    JOIN   COMPLEX_ORACLE.COMPLEX_ORACLE."TIMES" t
           ON us."time_id" = t."time_id"
    WHERE  t."calendar_quarter_id" IN (1772,1776)
    GROUP  BY us."cust_city", t."calendar_quarter_id"
),
growth_cities AS (   -- cities whose 2020-Q4 ≥ 120 % of 2019-Q4
    SELECT "city"
    FROM   city_qtr
    GROUP  BY "city"
    HAVING SUM(CASE WHEN "qtr" = 1772 THEN "city_sales" END) > 0
       AND SUM(CASE WHEN "qtr" = 1776 THEN "city_sales" END) >=
           1.20 * SUM(CASE WHEN "qtr" = 1772 THEN "city_sales" END)
),
prod_qtr AS (        -- product totals per quarter inside growth cities
    SELECT s."prod_id",
           t."calendar_quarter_id" AS "qtr",
           SUM(s."amount_sold")    AS "prod_sales"
    FROM   us_sales                       s
    JOIN   COMPLEX_ORACLE.COMPLEX_ORACLE."TIMES" t
           ON s."time_id" = t."time_id"
    WHERE  s."cust_city" IN (SELECT "city" FROM growth_cities)
      AND  t."calendar_quarter_id" IN (1772,1776)
    GROUP  BY s."prod_id", t."calendar_quarter_id"
),
prod_total AS (      -- overall (two-quarter) totals per product
    SELECT "prod_id",
           SUM("prod_sales") AS "total_sales"
    FROM   prod_qtr
    GROUP  BY "prod_id"
),
p80 AS (             -- 80-th percentile cut-off for total sales
    SELECT APPROX_PERCENTILE("total_sales", 0.80) AS "cutoff"
    FROM   prod_total
),
top20 AS (           -- products in the top 20 % of total sales
    SELECT pt."prod_id"
    FROM   prod_total pt, p80
    WHERE  pt."total_sales" >= p80."cutoff"
),
qtr_totals AS (      -- aggregate sales per quarter (growth-city scope)
    SELECT "qtr",
           SUM("prod_sales") AS "sum_qtr_sales"
    FROM   prod_qtr
    GROUP  BY "qtr"
),
share_qtr AS (       -- each top product’s share of its quarter’s total
    SELECT p."prod_id",
           p."qtr",
           p."prod_sales" / qt."sum_qtr_sales" AS "share"
    FROM   prod_qtr   p
    JOIN   qtr_totals qt ON p."qtr" = qt."qtr"
    WHERE  p."prod_id" IN (SELECT "prod_id" FROM top20)
),
change_calc AS (     -- compute percentage-point change of share
    SELECT "prod_id",
           MAX(CASE WHEN "qtr" = 1772 THEN "share" END) AS "share_2019q4",
           MAX(CASE WHEN "qtr" = 1776 THEN "share" END) AS "share_2020q4"
    FROM   share_qtr
    GROUP  BY "prod_id"
)
SELECT "prod_id",
       "share_2019q4",
       "share_2020q4",
       ("share_2020q4" - "share_2019q4") * 100 AS "percentage_point_change"
FROM   change_calc
ORDER  BY ABS("share_2020q4" - "share_2019q4") ASC, "prod_id"
LIMIT 1;