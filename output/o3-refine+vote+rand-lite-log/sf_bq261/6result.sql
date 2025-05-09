WITH monthly_product_profit AS (
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP("OI"."created_at" / 1000000))              AS month_start,
        "P"."id"                                                                   AS product_id,
        "P"."name"                                                                 AS product_name,
        SUM(COALESCE("P"."cost", 0))                                               AS total_cost,
        SUM(COALESCE("OI"."sale_price", 0)) - SUM(COALESCE("P"."cost", 0))         AS total_profit
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"        AS "OI"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"           AS "P"
          ON "OI"."product_id" = "P"."id"
    WHERE TO_TIMESTAMP("OI"."created_at" / 1000000) < '2024-01-01'     -- only months prior to Jan‑2024
    GROUP BY
        month_start,
        product_id,
        product_name
), ranked_products AS (
    SELECT
        month_start,
        product_id,
        product_name,
        total_cost,
        total_profit,
        ROW_NUMBER() OVER (
            PARTITION BY month_start
            ORDER BY total_profit DESC, product_id
        ) AS rn
    FROM monthly_product_profit
)
SELECT
    TO_CHAR(month_start, 'YYYY-MM')  AS month,
    product_id,
    product_name,
    ROUND(total_cost, 4)             AS total_cost,
    ROUND(total_profit, 4)           AS total_profit
FROM ranked_products
WHERE rn = 1
ORDER BY month_start;