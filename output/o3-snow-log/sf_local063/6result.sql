/*--------------------------------------------------------------
  Find the product (among the top-20 % by total sales) that shows
  the smallest percentage-point change in its share of total promo
  (id = 999) sales between Q4-2019 and Q4-2020, restricted to U.S.
  cities whose sales grew ≥ 20 % from 2019-Q4 to 2020-Q4.
--------------------------------------------------------------*/
WITH
/* 1.  U.S. country_id */
us_country AS (
    SELECT DISTINCT "country_id" AS cid
    FROM COMPLEX_ORACLE.COMPLEX_ORACLE.COUNTRIES
    WHERE "country_name" ILIKE '%United%States%'
),

/* 2.  Sales per city for each quarter (promo 999 only)            */
city_qtr_sales AS (
    SELECT  c."cust_city",
            SUM(CASE WHEN t."calendar_quarter_id" = 1772
                     THEN s."amount_sold" END) AS sales_2019q4,
            SUM(CASE WHEN t."calendar_quarter_id" = 1776
                     THEN s."amount_sold" END) AS sales_2020q4
    FROM COMPLEX_ORACLE.COMPLEX_ORACLE.SALES      s
    JOIN COMPLEX_ORACLE.COMPLEX_ORACLE.CUSTOMERS  c ON s."cust_id" = c."cust_id"
    JOIN COMPLEX_ORACLE.COMPLEX_ORACLE.TIMES      t ON s."time_id" = t."time_id",
         us_country
    WHERE c."country_id"  = us_country.cid
      AND s."promo_id"    = 999
      AND t."calendar_quarter_id" IN (1772,1776)
    GROUP BY c."cust_city"
),

/* 3.  Cities whose 2020-Q4 sales are ≥20 % higher than 2019-Q4     */
qualifying_cities AS (
    SELECT "cust_city"
    FROM   city_qtr_sales
    WHERE  sales_2019q4 > 0
      AND  (sales_2020q4 - sales_2019q4) / sales_2019q4 >= 0.20
),

/* 4.  Base sales rows limited to qualifying cities, two quarters   */
base_sales AS (
    SELECT s."prod_id",
           t."calendar_quarter_id",
           s."amount_sold"
    FROM COMPLEX_ORACLE.COMPLEX_ORACLE.SALES      s
    JOIN COMPLEX_ORACLE.COMPLEX_ORACLE.CUSTOMERS  c ON s."cust_id" = c."cust_id"
    JOIN COMPLEX_ORACLE.COMPLEX_ORACLE.TIMES      t ON s."time_id" = t."time_id",
         us_country
    WHERE c."country_id"        = us_country.cid
      AND s."promo_id"          = 999
      AND t."calendar_quarter_id" IN (1772,1776)
      AND c."cust_city" IN (SELECT "cust_city" FROM qualifying_cities)
),

/* 5.  Product-level sales per quarter                              */
prod_qtr_sales AS (
    SELECT "prod_id",
           "calendar_quarter_id",
           SUM("amount_sold") AS prod_sales
    FROM   base_sales
    GROUP BY "prod_id","calendar_quarter_id"
),

/* 6.  Total (both quarters) sales per product                      */
prod_totals AS (
    SELECT "prod_id",
           SUM(prod_sales) AS both_qtrs_sales
    FROM   prod_qtr_sales
    GROUP BY "prod_id"
),

/* 7.  Products that fall in the top 20 % of total sales            */
top20_products AS (
    SELECT "prod_id"
    FROM (
        SELECT "prod_id",
               both_qtrs_sales,
               NTILE(5) OVER (ORDER BY both_qtrs_sales DESC) AS ntl5
        FROM   prod_totals
    )
    WHERE ntl5 = 1
),

/* 8.  Total promo sales (all products) per quarter in the city set */
total_sales_qtr AS (
    SELECT "calendar_quarter_id",
           SUM("amount_sold") AS total_sales
    FROM   base_sales
    GROUP BY "calendar_quarter_id"
),

/* 9.  Assemble shares for the top-20 % products                    */
share_changes AS (
    SELECT  pqs."prod_id",
            SUM(CASE WHEN pqs."calendar_quarter_id" = 1772
                     THEN pqs.prod_sales END) AS sales_2019q4,
            SUM(CASE WHEN pqs."calendar_quarter_id" = 1776
                     THEN pqs.prod_sales END) AS sales_2020q4,
            ROUND(
                SUM(CASE WHEN pqs."calendar_quarter_id" = 1772
                         THEN pqs.prod_sales END)
                / (SELECT total_sales FROM total_sales_qtr WHERE "calendar_quarter_id" = 1772) * 100,
                2
            ) AS share_2019q4_pct,
            ROUND(
                SUM(CASE WHEN pqs."calendar_quarter_id" = 1776
                         THEN pqs.prod_sales END)
                / (SELECT total_sales FROM total_sales_qtr WHERE "calendar_quarter_id" = 1776) * 100,
                2
            ) AS share_2020q4_pct
    FROM   prod_qtr_sales pqs
    WHERE  pqs."prod_id" IN (SELECT "prod_id" FROM top20_products)
    GROUP BY pqs."prod_id"
)

/* 10.  Return the product with the smallest absolute change in share */
SELECT  "prod_id",
        sales_2019q4,
        sales_2020q4,
        share_2019q4_pct,
        share_2020q4_pct,
        ROUND(share_2020q4_pct - share_2019q4_pct, 2) AS pct_point_change
FROM    share_changes
ORDER BY ABS(share_2020q4_pct - share_2019q4_pct) ASC,
         "prod_id"
LIMIT 1;