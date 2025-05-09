WITH total_sales_per_product AS (
    SELECT s."prod_id", SUM(s."amount_sold") AS "total_sales"
    FROM "COMPLEX_ORACLE"."COMPLEX_ORACLE"."SALES" s
    GROUP BY s."prod_id"
),
product_count AS (
    SELECT COUNT(*) AS total_products FROM total_sales_per_product
),
ranked_products AS (
    SELECT 
        t."prod_id", 
        t."total_sales",
        DENSE_RANK() OVER (ORDER BY t."total_sales" DESC) AS sales_rank
    FROM total_sales_per_product t
),
top_20_percent_products AS (
    SELECT rp."prod_id", rp."total_sales"
    FROM ranked_products rp, product_count pc
    WHERE rp.sales_rank <= pc.total_products * 0.2
),
products AS (
    SELECT "prod_id", "prod_name"
    FROM "COMPLEX_ORACLE"."COMPLEX_ORACLE"."PRODUCTS"
),
top_products AS (
    SELECT tpp."prod_id", tpp."total_sales", p."prod_name"
    FROM top_20_percent_products tpp
    JOIN products p ON tpp."prod_id" = p."prod_id"
),
sales_2019 AS (
    SELECT s."prod_id", SUM(s."amount_sold") AS "total_sales_2019"
    FROM "COMPLEX_ORACLE"."COMPLEX_ORACLE"."SALES" s
    JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."TIMES" t ON s."time_id" = t."time_id"
    JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."CUSTOMERS" c ON s."cust_id" = c."cust_id"
    JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."COUNTRIES" co ON c."country_id" = co."country_id"
    WHERE t."calendar_year" = 2019
      AND t."calendar_quarter_number" = 4
      AND co."country_name" = 'United States of America'
      AND s."promo_id" = 999
      AND s."prod_id" IN (SELECT "prod_id" FROM top_products)
    GROUP BY s."prod_id"
),
total_sales_2019_all AS (
    SELECT SUM("total_sales_2019") AS "total_sales_all_2019"
    FROM sales_2019
),
sales_2020 AS (
    SELECT s."prod_id", SUM(s."amount_sold") AS "total_sales_2020"
    FROM "COMPLEX_ORACLE"."COMPLEX_ORACLE"."SALES" s
    JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."TIMES" t ON s."time_id" = t."time_id"
    JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."CUSTOMERS" c ON s."cust_id" = c."cust_id"
    JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."COUNTRIES" co ON c."country_id" = co."country_id"
    WHERE t."calendar_year" = 2020
      AND t."calendar_quarter_number" = 4
      AND co."country_name" = 'United States of America'
      AND s."promo_id" = 999
      AND s."prod_id" IN (SELECT "prod_id" FROM top_products)
    GROUP BY s."prod_id"
),
total_sales_2020_all AS (
    SELECT SUM("total_sales_2020") AS "total_sales_all_2020"
    FROM sales_2020
),
product_sales_shares AS (
    SELECT 
        tp."prod_id",
        tp."prod_name",
        COALESCE(s2019."total_sales_2019", 0) AS "total_sales_2019",
        COALESCE(s2020."total_sales_2020", 0) AS "total_sales_2020"
    FROM top_products tp
    LEFT JOIN sales_2019 s2019 ON tp."prod_id" = s2019."prod_id"
    LEFT JOIN sales_2020 s2020 ON tp."prod_id" = s2020."prod_id"
),
sales_shares AS (
    SELECT 
        ps."prod_id",
        ps."prod_name",
        ps."total_sales_2019",
        ps."total_sales_2020",
        COALESCE(ps."total_sales_2019" / NULLIF((SELECT "total_sales_all_2019" FROM total_sales_2019_all), 0), 0) AS "sales_share_2019",
        COALESCE(ps."total_sales_2020" / NULLIF((SELECT "total_sales_all_2020" FROM total_sales_2020_all), 0), 0) AS "sales_share_2020",
        ROUND(ABS(
            COALESCE(ps."total_sales_2019" / NULLIF((SELECT "total_sales_all_2019" FROM total_sales_2019_all), 0), 0)
            - COALESCE(ps."total_sales_2020" / NULLIF((SELECT "total_sales_all_2020" FROM total_sales_2020_all), 0), 0)
        ), 4) AS "change_in_sales_share"
    FROM product_sales_shares ps
)
SELECT 
    "prod_name" AS "Product_Name",
    "change_in_sales_share" AS "Change_in_Sales_Share"
FROM sales_shares
ORDER BY "change_in_sales_share" ASC NULLS LAST
LIMIT 1;