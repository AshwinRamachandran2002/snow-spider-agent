/*  Find the U.S. product (promo_id = 999, fast-growing cities only) that
    lies in the top-20 % of combined sales and shows the smallest
    percentage-point change in its sales share between Q4-2019 (1772) and
    Q4-2020 (1776).  */

WITH us_id AS (              -- United States country_id
    SELECT "country_id" AS id
    FROM   COMPLEX_ORACLE.COMPLEX_ORACLE.COUNTRIES
    WHERE  "country_name" ILIKE '%United%States%'
    LIMIT  1
),

/* ----------  city-level sales by quarter  ---------- */
q19 AS (
    SELECT cu."cust_city",
           SUM(s."amount_sold") AS sales_2019
    FROM   COMPLEX_ORACLE.COMPLEX_ORACLE.SALES      s
    JOIN   COMPLEX_ORACLE.COMPLEX_ORACLE.CUSTOMERS  cu ON s."cust_id" = cu."cust_id"
    JOIN   COMPLEX_ORACLE.COMPLEX_ORACLE.TIMES      t  ON s."time_id" = t."time_id"
    WHERE  cu."country_id"        = (SELECT id FROM us_id)
      AND  s."promo_id"           = 999
      AND  t."calendar_quarter_id"= 1772          -- Q4-2019
    GROUP  BY cu."cust_city"
),
q20 AS (
    SELECT cu."cust_city",
           SUM(s."amount_sold") AS sales_2020
    FROM   COMPLEX_ORACLE.COMPLEX_ORACLE.SALES      s
    JOIN   COMPLEX_ORACLE.COMPLEX_ORACLE.CUSTOMERS  cu ON s."cust_id" = cu."cust_id"
    JOIN   COMPLEX_ORACLE.COMPLEX_ORACLE.TIMES      t  ON s."time_id" = t."time_id"
    WHERE  cu."country_id"        = (SELECT id FROM us_id)
      AND  s."promo_id"           = 999
      AND  t."calendar_quarter_id"= 1776          -- Q4-2020
    GROUP  BY cu."cust_city"
),

/* ----------  keep only cities with ≥20 % YoY growth  ---------- */
fast_cities AS (
    SELECT q19."cust_city"
    FROM   q19
    JOIN   q20  ON q19."cust_city" = q20."cust_city"
    WHERE  (q20.sales_2020 - q19.sales_2019)
           / NULLIF(q19.sales_2019,0)  >= 0.20
),

/* ----------  sales rows restricted to fast-growing cities  ---------- */
sales_filt AS (
    SELECT s."prod_id",
           t."calendar_quarter_id",
           s."amount_sold"
    FROM   COMPLEX_ORACLE.COMPLEX_ORACLE.SALES      s
    JOIN   COMPLEX_ORACLE.COMPLEX_ORACLE.CUSTOMERS  cu ON s."cust_id" = cu."cust_id"
    JOIN   COMPLEX_ORACLE.COMPLEX_ORACLE.TIMES      t  ON s."time_id" = t."time_id"
    WHERE  cu."country_id"       = (SELECT id FROM us_id)
      AND  cu."cust_city"        IN (SELECT "cust_city" FROM fast_cities)
      AND  s."promo_id"          = 999
      AND  t."calendar_quarter_id" IN (1772,1776)
),

/* ----------  total (both quarters) sales per product  ---------- */
prod_tot AS (
    SELECT "prod_id",
           SUM("amount_sold") AS tot_sales
    FROM   sales_filt
    GROUP  BY "prod_id"
),

/* ----------  top 20 % products by total sales  ---------- */
top20 AS (
    SELECT  "prod_id"
    FROM   (
        SELECT "prod_id",
               tot_sales,
               CUME_DIST() OVER (ORDER BY tot_sales DESC) AS cd
        FROM   prod_tot
    )
    WHERE  cd <= 0.20
),

/* ----------  quarter-level sales for top products  ---------- */
prod_qtr AS (
    SELECT "prod_id",
           "calendar_quarter_id",
           SUM("amount_sold") AS qtr_sales
    FROM   sales_filt
    WHERE  "prod_id" IN (SELECT "prod_id" FROM top20)
    GROUP  BY "prod_id", "calendar_quarter_id"
),

/* ----------  overall sales totals per quarter (denominator)  ---------- */
quarter_tot AS (
    SELECT "calendar_quarter_id",
           SUM("amount_sold") AS grand_sales
    FROM   sales_filt
    GROUP  BY "calendar_quarter_id"
),

/* ----------  compute share & percentage-point change  ---------- */
share_change AS (
    SELECT p19."prod_id",
           (p19.qtr_sales / q19t.grand_sales) AS share_2019,
           (p20.qtr_sales / q20t.grand_sales) AS share_2020,
           ABS( (p20.qtr_sales / q20t.grand_sales)
              - (p19.qtr_sales / q19t.grand_sales) )       AS pct_point_change
    FROM   prod_qtr      p19
    JOIN   prod_qtr      p20   ON p19."prod_id" = p20."prod_id"
                               AND p20."calendar_quarter_id" = 1776
    JOIN   quarter_tot   q19t  ON q19t."calendar_quarter_id" = 1772
    JOIN   quarter_tot   q20t  ON q20t."calendar_quarter_id" = 1776
    WHERE  p19."calendar_quarter_id" = 1772
)

/* ----------  final answer  ---------- */
SELECT  "prod_id",
        pct_point_change
FROM    share_change
ORDER BY pct_point_change ASC NULLS LAST
LIMIT 1;