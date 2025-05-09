WITH order_product_month AS (
    SELECT
        DATE_TRUNC('month',
                   TO_TIMESTAMP("oi"."created_at" / 1e6))                 AS "month",
        "oi"."product_id",
        "p"."name"                                                     AS "product_name",
        SUM("p"."cost")                                                AS "total_cost",
        SUM( COALESCE("oi"."sale_price",0) - "p"."cost")               AS "total_profit"
    FROM
        THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  AS "oi"
        JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS" AS "p"
          ON "oi"."product_id" = "p"."id"
    WHERE
        DATE_TRUNC('month',
                   TO_TIMESTAMP("oi"."created_at" / 1e6)) < DATE '2024-01-01'
    GROUP BY
        "month",
        "oi"."product_id",
        "p"."name"
),
ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY "month"
                           ORDER BY "total_profit" DESC NULLS LAST) AS "rn"
    FROM
        order_product_month
)
SELECT
    "month",
    "product_id",
    "product_name",
    "total_cost",
    "total_profit"
FROM
    ranked
WHERE
    "rn" = 1
ORDER BY
    "month";