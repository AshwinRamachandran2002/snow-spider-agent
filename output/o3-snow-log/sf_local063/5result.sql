/*-----------------------------------------------------------
  Find the top-20 % revenue products (promo_id = 999) sold to
  U.S. customers whose cities grew ≥20 % from 2019-Q4 (1772)
  to 2020-Q4 (1776), then pick the one whose share of total
  sales changed the least between these two quarters.
-----------------------------------------------------------*/
WITH us_country AS (          -- United States (per earlier lookup)
    SELECT 52772 AS "country_id"                -- United States of America
),

/* -------- 1. Cities whose sales grew at least 20 % -------- */
good_cities AS (
    /* 2019-Q4 sales by city */
    SELECT pre."cust_city"
    FROM (
        SELECT c."cust_city",
               SUM(s."amount_sold") AS sales_2019
        FROM COMPLEX_ORACLE.COMPLEX_ORACLE.SALES      s
        JOIN COMPLEX_ORACLE.COMPLEX_ORACLE.TIMES      t ON s."time_id" = t."time_id"
        JOIN COMPLEX_ORACLE.COMPLEX_ORACLE.CUSTOMERS  c ON s."cust_id" = c."cust_id"
        JOIN us_country  u ON c."country_id" = u."country_id"
        WHERE s."promo_id" = 999
          AND t."calendar_quarter_id" = 1772          -- 2019-Q4
        GROUP BY c."cust_city"
    )  pre
    /* 2020-Q4 sales by the same city */
    JOIN (
        SELECT c."cust_city",
               SUM(s."amount_sold") AS sales_2020
        FROM COMPLEX_ORACLE.COMPLEX_ORACLE.SALES      s
        JOIN COMPLEX_ORACLE.COMPLEX_ORACLE.TIMES      t ON s."time_id" = t."time_id"
        JOIN COMPLEX_ORACLE.COMPLEX_ORACLE.CUSTOMERS  c ON s."cust_id" = c."cust_id"
        JOIN us_country  u ON c."country_id" = u."country_id"
        WHERE s."promo_id" = 999
          AND t."calendar_quarter_id" = 1776          -- 2020-Q4
        GROUP BY c."cust_city"
    )  post  ON pre."cust_city" = post."cust_city"
    WHERE post.sales_2020 >= pre.sales_2019 * 1.20     -- ≥20 % growth
),

/* -------- 2. Product sales in the two quarters -------- */
product_qtr AS (
    SELECT s."prod_id",
           t."calendar_quarter_id",
           SUM(s."amount_sold") AS sales
    FROM COMPLEX_ORACLE.COMPLEX_ORACLE.SALES      s
    JOIN COMPLEX_ORACLE.COMPLEX_ORACLE.TIMES      t ON s."time_id" = t."time_id"
    JOIN COMPLEX_ORACLE.COMPLEX_ORACLE.CUSTOMERS  c ON s."cust_id" = c."cust_id"
    JOIN good_cities g ON c."cust_city" = g."cust_city"
    WHERE s."promo_id" = 999
      AND t."calendar_quarter_id" IN (1772,1776)      -- 2019-Q4 & 2020-Q4
    GROUP BY s."prod_id", t."calendar_quarter_id"
),

/* -------- 3. Total sales by quarter -------- */
totals AS (
    SELECT "calendar_quarter_id",
           SUM(sales) AS tot_sales
    FROM product_qtr
    GROUP BY "calendar_quarter_id"
),

/* -------- 4. Share of each product in each quarter -------- */
shares AS (
    SELECT p."prod_id",
           p."calendar_quarter_id",
           p.sales,
           p.sales / t.tot_sales AS share
    FROM product_qtr p
    JOIN totals     t ON p."calendar_quarter_id" = t."calendar_quarter_id"
),

/* -------- 5. Keep only products in the top 20 % of total revenue -------- */
top20 AS (
    SELECT "prod_id",
           SUM(sales) AS total_two_qtrs
    FROM product_qtr
    GROUP BY "prod_id"
    QUALIFY NTILE(5) OVER (ORDER BY SUM(sales) DESC) = 1   -- top 20 %
)

/* -------- 6. Final answer: product with smallest share change -------- */
SELECT s19."prod_id",
       p."prod_name",
       ROUND(s19.share, 8) AS share_2019Q4,
       ROUND(s20.share, 8) AS share_2020Q4,
       ROUND(ABS(s20.share - s19.share), 8) AS share_change
FROM shares s19
JOIN shares s20  ON s20."prod_id" = s19."prod_id"
                AND s20."calendar_quarter_id" = 1776        -- 2020-Q4
JOIN top20  t    ON t."prod_id" = s19."prod_id"
JOIN COMPLEX_ORACLE.COMPLEX_ORACLE.PRODUCTS p ON p."prod_id" = s19."prod_id"
WHERE s19."calendar_quarter_id" = 1772                      -- 2019-Q4
ORDER BY share_change ASC
LIMIT 1;