WITH products_no_promo_2019 AS (
    SELECT DISTINCT s."prod_id"
    FROM
        COMPLEX_ORACLE.COMPLEX_ORACLE."SALES" s
        JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."CUSTOMERS" c ON s."cust_id" = c."cust_id"
        JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."COUNTRIES" co ON c."country_id" = co."country_id"
        JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."TIMES" t ON s."time_id" = t."time_id"
    WHERE
        t."calendar_year" = 2019
        AND t."calendar_quarter_number" = 4
        AND co."country_name" = 'United States of America'
        AND s."promo_id" = 999  -- No Promotion
),
products_no_promo_2020 AS (
    SELECT DISTINCT s."prod_id"
    FROM
        COMPLEX_ORACLE.COMPLEX_ORACLE."SALES" s
        JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."CUSTOMERS" c ON s."cust_id" = c."cust_id"
        JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."COUNTRIES" co ON c."country_id" = co."country_id"
        JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."TIMES" t ON s."time_id" = t."time_id"
    WHERE
        t."calendar_year" = 2020
        AND t."calendar_quarter_number" = 4
        AND co."country_name" = 'United States of America'
        AND s."promo_id" = 999  -- No Promotion
),
products_no_promo_both_years AS (
    SELECT p2019."prod_id"
    FROM products_no_promo_2019 p2019
    INNER JOIN products_no_promo_2020 p2020 ON p2019."prod_id" = p2020."prod_id"
),
sales_data AS (
    SELECT
        s."prod_id",
        t."calendar_year",
        SUM(s."amount_sold") AS "product_sales"
    FROM
        COMPLEX_ORACLE.COMPLEX_ORACLE."SALES" s
        JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."CUSTOMERS" c ON s."cust_id" = c."cust_id"
        JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."COUNTRIES" co ON c."country_id" = co."country_id"
        JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."TIMES" t ON s."time_id" = t."time_id"
    WHERE
        t."calendar_year" IN (2019, 2020)
        AND t."calendar_quarter_number" = 4
        AND co."country_name" = 'United States of America'
        AND s."promo_id" = 999  -- No Promotion
        AND s."prod_id" IN (SELECT "prod_id" FROM products_no_promo_both_years)
    GROUP BY
        s."prod_id",
        t."calendar_year"
),
total_sales_per_year AS (
    SELECT
        t."calendar_year",
        SUM(s."amount_sold") AS "total_sales"
    FROM
        COMPLEX_ORACLE.COMPLEX_ORACLE."SALES" s
        JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."CUSTOMERS" c ON s."cust_id" = c."cust_id"
        JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."COUNTRIES" co ON c."country_id" = co."country_id"
        JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."TIMES" t ON s."time_id" = t."time_id"
    WHERE
        t."calendar_year" IN (2019, 2020)
        AND t."calendar_quarter_number" = 4
        AND co."country_name" = 'United States of America'
        AND s."promo_id" = 999  -- No Promotion
        AND s."prod_id" IN (SELECT "prod_id" FROM products_no_promo_both_years)
    GROUP BY
        t."calendar_year"
),
sales_with_shares AS (
    SELECT
        sd."prod_id",
        sd."calendar_year",
        sd."product_sales",
        ts."total_sales",
        sd."product_sales" / ts."total_sales" AS "sales_share"
    FROM
        sales_data sd
        JOIN total_sales_per_year ts ON sd."calendar_year" = ts."calendar_year"
),
total_sales_per_product AS (
    SELECT
        "prod_id",
        SUM("product_sales") AS "total_sales_product"
    FROM
        sales_data
    GROUP BY
        "prod_id"
),
sales_threshold AS (
    SELECT
        APPROX_PERCENTILE("total_sales_product", 0.8) AS "sales_80th_percentile"
    FROM total_sales_per_product
),
top_products AS (
    SELECT
        tsp."prod_id"
    FROM
        total_sales_per_product tsp,
        sales_threshold st
    WHERE
        tsp."total_sales_product" >= st."sales_80th_percentile"
),
change_in_sales_share AS (
    SELECT
        sws1."prod_id",
        ROUND(sws1."sales_share", 4) AS "sales_share_2019",
        ROUND(sws2."sales_share", 4) AS "sales_share_2020",
        ROUND(sws2."sales_share" - sws1."sales_share", 4) AS "change_in_sales_share"
    FROM
        sales_with_shares sws1
        JOIN sales_with_shares sws2 ON sws1."prod_id" = sws2."prod_id"
        WHERE
            sws1."calendar_year" = 2019
            AND sws2."calendar_year" = 2020
            AND sws1."prod_id" IN (SELECT "prod_id" FROM top_products)
)
SELECT
    "prod_id" AS "Product_ID",
    "change_in_sales_share" AS "Change_in_Sales_Share"
FROM
    change_in_sales_share
ORDER BY
    "Change_in_Sales_Share" DESC NULLS LAST
;