WITH order_item_with_cost AS (
    SELECT
        DATE_TRUNC(
            'month',
            TO_TIMESTAMP("OI"."created_at" / 1000000)
        )                                                            AS "month",
        "P"."id"                                                     AS "product_id",
        "P"."name"                                                   AS "product_name",
        "P"."cost"                                                   AS "unit_cost",
        "OI"."sale_price"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS  AS "OI"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.PRODUCTS     AS "P"
      ON "OI"."product_id" = "P"."id"
    WHERE TO_TIMESTAMP("OI"."created_at" / 1000000) < '2024-01-01'
),
monthly_product_profit AS (
    SELECT
        "month",
        "product_id",
        "product_name",
        SUM("unit_cost")                                 AS "total_cost",
        SUM("sale_price" - "unit_cost")                  AS "total_profit"
    FROM order_item_with_cost
    GROUP BY
        "month",
        "product_id",
        "product_name"
),
ranked_products AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY "month"
            ORDER BY "total_profit" DESC, "product_id" ASC
        ) AS "rn"
    FROM monthly_product_profit
)
SELECT
    "month",
    "product_id",
    "product_name",
    "total_cost",
    "total_profit"
FROM ranked_products
WHERE "rn" = 1
ORDER BY "month";