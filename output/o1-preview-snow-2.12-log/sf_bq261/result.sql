WITH monthly_product_profits AS (
    SELECT
        DATE_TRUNC('MONTH', TO_TIMESTAMP(oi."created_at" / 1000000)) AS "Month",
        oi."product_id",
        p."name" AS "Product_Name",
        SUM(p."cost") AS "Total_Cost",
        SUM(oi."sale_price" - p."cost") AS "Total_Profit"
    FROM
        "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS" oi
    JOIN
        "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."PRODUCTS" p
            ON oi."product_id" = p."id"
    WHERE
        TO_TIMESTAMP(oi."created_at" / 1000000) < '2024-01-01'
    GROUP BY
        "Month", oi."product_id", p."name"
),
ranked_products AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY "Month"
            ORDER BY "Total_Profit" DESC NULLS LAST
        ) AS "Rank"
    FROM
        monthly_product_profits
)
SELECT
    "Month",
    "Product_Name",
    ROUND("Total_Cost", 4) AS "Total_Cost",
    ROUND("Total_Profit", 4) AS "Total_Profit"
FROM
    ranked_products
WHERE
    "Rank" = 1
ORDER BY
    "Month";