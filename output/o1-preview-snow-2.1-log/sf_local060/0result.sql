WITH product_sales AS (
    SELECT 
        s."prod_id", 
        SUM(CASE WHEN t."calendar_year" = 2019 THEN s."amount_sold" ELSE 0 END) AS total_sales_2019,
        SUM(CASE WHEN t."calendar_year" = 2020 THEN s."amount_sold" ELSE 0 END) AS total_sales_2020,
        SUM(s."amount_sold") AS total_sales
    FROM "COMPLEX_ORACLE"."COMPLEX_ORACLE"."SALES" s
    JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."TIMES" t 
        ON s."time_id" = t."time_id"
    JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."CUSTOMERS" c 
        ON s."cust_id" = c."cust_id"
    JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."COUNTRIES" co 
        ON c."country_id" = co."country_id"
    WHERE
        t."calendar_year" IN (2019, 2020)
        AND t."calendar_month_number" IN (10, 11, 12)
        AND co."country_iso_code" = 'US'
        AND s."promo_id" = 999
        AND s."prod_id" NOT IN (
            SELECT DISTINCT s2."prod_id"
            FROM "COMPLEX_ORACLE"."COMPLEX_ORACLE"."SALES" s2
            JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."TIMES" t2 
                ON s2."time_id" = t2."time_id"
            WHERE 
                t2."calendar_year" IN (2019, 2020) 
                AND t2."calendar_month_number" IN (10, 11, 12)
                AND s2."promo_id" <> 999
        )
    GROUP BY s."prod_id"
),
ranked_products AS (
    SELECT 
        ps.*, 
        NTILE(5) OVER (ORDER BY ps.total_sales DESC) AS tile
    FROM product_sales ps
),
top_products AS (
    SELECT *
    FROM ranked_products
    WHERE tile = 1
),
total_sales_top AS (
    SELECT 
        SUM(total_sales_2019) AS total_sales_2019_top,
        SUM(total_sales_2020) AS total_sales_2020_top
    FROM top_products
)
SELECT 
    tp."prod_id" AS "Product_ID",
    ROUND(
        (tp.total_sales_2020 / NULLIF(ts.total_sales_2020_top, 0)) - 
        (tp.total_sales_2019 / NULLIF(ts.total_sales_2019_top, 0)),
        4
    ) AS "Change_in_Sales_Share"
FROM top_products tp
CROSS JOIN total_sales_top ts
ORDER BY "Change_in_Sales_Share" DESC NULLS LAST;