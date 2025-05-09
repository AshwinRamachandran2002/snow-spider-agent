WITH profit_per_product AS (
    SELECT
        TO_CHAR(TO_TIMESTAMP_NTZ(o."created_at" / 1e6), 'YYYY-MM') AS "Month",
        p."name" AS "Product_Name",
        ROUND(SUM(p."cost"), 4) AS "Total_Cost",
        ROUND(SUM(o."sale_price" - p."cost"), 4) AS "Total_Profit",
        ROW_NUMBER() OVER (
            PARTITION BY TO_CHAR(TO_TIMESTAMP_NTZ(o."created_at" / 1e6), 'YYYY-MM')
            ORDER BY SUM(o."sale_price" - p."cost") DESC NULLS LAST
        ) AS rn
    FROM
        THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS" o
    JOIN
        THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS" p
        ON o."product_id" = p."id"
    WHERE
        TO_TIMESTAMP_NTZ(o."created_at" / 1e6) < TO_TIMESTAMP_NTZ('2024-01-01', 'YYYY-MM-DD')
    GROUP BY
        TO_CHAR(TO_TIMESTAMP_NTZ(o."created_at" / 1e6), 'YYYY-MM'),
        p."name"
)
SELECT
    "Month",
    "Product_Name",
    "Total_Cost",
    "Total_Profit"
FROM
    profit_per_product
WHERE
    rn = 1
ORDER BY
    "Month";