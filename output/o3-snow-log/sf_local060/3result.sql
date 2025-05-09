WITH US_Q4_SALES AS (          /* Q4-2019 & Q4-2020 sales in U.S. cities, no promotions */
    SELECT
        s."amount_sold",
        cu."cust_city"                      AS "city",
        t."calendar_year"                   AS "year",
        s."prod_id"
    FROM COMPLEX_ORACLE.COMPLEX_ORACLE."SALES"     s
    JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."CUSTOMERS" cu  ON s."cust_id"   = cu."cust_id"
    JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."COUNTRIES" co  ON cu."country_id"= co."country_id"
    JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."TIMES"     t   ON s."time_id"    = t."time_id"
    WHERE co."country_iso_code" = 'US'                 -- United States
      AND (s."promo_id" IS NULL OR s."promo_id" = 999) -- non-promoted sales
      AND t."calendar_year" IN (2019, 2020)
      AND t."calendar_quarter_number" = 4
),
CITY_TOTALS AS (                /* city-level Q4 totals by year */
    SELECT "city",
           "year",
           SUM("amount_sold") AS "city_sales"
    FROM   US_Q4_SALES
    GROUP  BY "city","year"
),
CITIES_GROWTH AS (              /* cities with ≥20 % growth 2019→2020 */
    SELECT c20."city"
    FROM   CITY_TOTALS c19
    JOIN   CITY_TOTALS c20
           ON c19."city" = c20."city"
          AND c19."year" = 2019
          AND c20."year" = 2020
    WHERE  c20."city_sales" >= 1.2 * c19."city_sales"
),
FILTERED_SALES AS (             /* keep only growing cities */
    SELECT s.*
    FROM   US_Q4_SALES s
    JOIN   CITIES_GROWTH g ON s."city" = g."city"
),
PRODUCT_TOTAL AS (              /* total (2019+2020) sales per product */
    SELECT "prod_id",
           SUM("amount_sold") AS "tot_sales"
    FROM   FILTERED_SALES
    GROUP  BY "prod_id"
),
PRODUCT_RANK AS (               /* rank products and count */
    SELECT "prod_id",
           "tot_sales",
           ROW_NUMBER() OVER (ORDER BY "tot_sales" DESC) AS "rn",
           COUNT(*)  OVER ()                             AS "cnt"
    FROM   PRODUCT_TOTAL
),
TOP_PRODUCTS AS (               /* top 20 % of products */
    SELECT "prod_id"
    FROM   PRODUCT_RANK
    WHERE  "rn" <= CEIL("cnt" * 0.20)
),
PROD_YEAR_SALES AS (            /* top-product sales by year */
    SELECT fs."prod_id",
           fs."year",
           SUM(fs."amount_sold") AS "prod_sales"
    FROM   FILTERED_SALES fs
    JOIN   TOP_PRODUCTS  tp ON fs."prod_id" = tp."prod_id"
    GROUP  BY fs."prod_id", fs."year"
),
YEAR_TOTALS AS (                /* total sales (all prods) by year */
    SELECT "year",
           SUM("amount_sold") AS "year_sales"
    FROM   FILTERED_SALES
    GROUP  BY "year"
),
PROD_SHARES AS (                /* share of each product per year */
    SELECT pys."prod_id",
           pys."year",
           pys."prod_sales" / yt."year_sales" AS "share"
    FROM   PROD_YEAR_SALES pys
    JOIN   YEAR_TOTALS    yt ON pys."year" = yt."year"
),
PROD_PIVOT AS (                 /* shares side-by-side & change */
    SELECT
        COALESCE(s19."prod_id", s20."prod_id")                 AS "prod_id",
        COALESCE(s19."share", 0)                               AS "share_2019",
        COALESCE(s20."share", 0)                               AS "share_2020",
        COALESCE(s20."share", 0) - COALESCE(s19."share", 0)    AS "share_change"
    FROM (SELECT * FROM PROD_SHARES WHERE "year" = 2019) s19
    FULL OUTER JOIN (SELECT * FROM PROD_SHARES WHERE "year" = 2020) s20
         ON s19."prod_id" = s20."prod_id"
)
SELECT
    p."prod_name",
    pp."prod_id",
    pp."share_2019",
    pp."share_2020",
    pp."share_change"
FROM   PROD_PIVOT pp
JOIN   COMPLEX_ORACLE.COMPLEX_ORACLE."PRODUCTS" p
       ON pp."prod_id" = p."prod_id"
ORDER  BY pp."share_change" DESC NULLS LAST;