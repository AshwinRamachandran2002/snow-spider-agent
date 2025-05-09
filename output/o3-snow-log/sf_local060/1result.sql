WITH sales_us_q4 AS (      /*  Q4-only, no-promotion sales in the U.S. */
    SELECT 
        c."cust_city"                       AS "city",
        t."calendar_year"                   AS "year",
        s."prod_id"                         AS "prod_id",
        s."amount_sold"                     AS "amount_sold"
    FROM COMPLEX_ORACLE.COMPLEX_ORACLE.SALES      s
    JOIN COMPLEX_ORACLE.COMPLEX_ORACLE.CUSTOMERS  c  ON s."cust_id" = c."cust_id"
    JOIN COMPLEX_ORACLE.COMPLEX_ORACLE.COUNTRIES  co ON c."country_id" = co."country_id"
    JOIN COMPLEX_ORACLE.COMPLEX_ORACLE.TIMES      t  ON s."time_id" = t."time_id"
    WHERE co."country_name" IN ('United States of America','United States')
      AND s."promo_id"               = 999                --  no promotion
      AND t."calendar_quarter_number" = 4                 --  Q4
      AND t."calendar_year"          IN (2019,2020)
),                                                          /* city totals per year            */
city_sales AS (
    SELECT "city","year", SUM("amount_sold") AS "city_total"
    FROM   sales_us_q4
    GROUP  BY "city","year"
),                                                          /* cities with ≥20 % Q4 growth      */
growth_cities AS (
    SELECT c19."city"
    FROM   city_sales c19
    JOIN   city_sales c20 
           ON c19."city" = c20."city"
          AND c19."year" = 2019
          AND c20."year" = 2020
    WHERE  c20."city_total" >= c19."city_total" * 1.20
),                                                          /* sales restricted to growth cities*/
filtered_sales AS (
    SELECT s.*
    FROM   sales_us_q4 s
    WHERE  s."city" IN (SELECT "city" FROM growth_cities)
),                                                          /* overall (2019+2020) product sales*/
product_overall AS (
    SELECT "prod_id", SUM("amount_sold") AS "total_sales"
    FROM   filtered_sales
    GROUP  BY "prod_id"
),                                                          /* rank products & keep top 20 %    */
ranked_products AS (
    SELECT 
        "prod_id",
        "total_sales",
        PERCENT_RANK() OVER (ORDER BY "total_sales" DESC) AS "p_rank"
    FROM product_overall
),
top_products AS (
    SELECT "prod_id"
    FROM   ranked_products
    WHERE  "p_rank" <= 0.20                                --  top 20 %
),                                                          /* product sales per Q4 year        */
product_quarter_sales AS (
    SELECT 
        fs."prod_id",
        fs."year",
        SUM(fs."amount_sold") AS "sales"
    FROM   filtered_sales fs
    WHERE  fs."prod_id" IN (SELECT "prod_id" FROM top_products)
    GROUP  BY fs."prod_id", fs."year"
),                                                          /* total sales for share denominator*/
quarter_totals AS (
    SELECT "year", SUM("amount_sold") AS "total_sales"
    FROM   filtered_sales
    GROUP  BY "year"
),                                                          /* compute product shares           */
shares AS (
    SELECT 
        pqs."prod_id",
        pqs."year",
        pqs."sales" / qt."total_sales" AS "share"
    FROM   product_quarter_sales pqs
    JOIN   quarter_totals       qt  ON pqs."year" = qt."year"
),                                                          /* pivot 2019 vs 2020 shares        */
share_pivot AS (
    SELECT
        "prod_id",
        COALESCE(MAX(CASE WHEN "year" = 2019 THEN "share" END),0) AS "share_2019",
        COALESCE(MAX(CASE WHEN "year" = 2020 THEN "share" END),0) AS "share_2020"
    FROM   shares
    GROUP  BY "prod_id"
)
SELECT 
    sp."prod_id",
    pr."prod_name",
    ROUND(sp."share_2019",4)          AS "share_2019",
    ROUND(sp."share_2020",4)          AS "share_2020",
    ROUND(sp."share_2020" - sp."share_2019",4) AS "share_change"
FROM   share_pivot                           sp
JOIN   COMPLEX_ORACLE.COMPLEX_ORACLE.PRODUCTS pr
       ON sp."prod_id" = pr."prod_id"
ORDER  BY "share_change" DESC NULLS LAST;