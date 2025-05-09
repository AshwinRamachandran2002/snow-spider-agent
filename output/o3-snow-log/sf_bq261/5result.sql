WITH order_item_monthly AS (
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP_NTZ("oi"."created_at" / 1000000))                       AS "month",
        "oi"."product_id",
        "p"."name"                                                                               AS "product_name",
        SUM("p"."cost")                                                                          AS "total_cost",
        SUM("oi"."sale_price")                                                                   AS "total_sales",
        SUM("oi"."sale_price") - SUM("p"."cost")                                                 AS "total_profit"
    FROM  "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS"  AS "oi"
    JOIN  "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."PRODUCTS"     AS "p"
          ON "oi"."product_id" = "p"."id"
    WHERE DATE_TRUNC('month', TO_TIMESTAMP_NTZ("oi"."created_at" / 1000000)) < '2024-01-01'
    GROUP BY
        1, 2, 3
),
ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY "month" ORDER BY "total_profit" DESC) AS "rn"
    FROM order_item_monthly
)
SELECT
    TO_CHAR("month", 'YYYY-MM')  AS "month",
    "product_id",
    "product_name",
    ROUND("total_cost",   4)     AS "total_cost",
    ROUND("total_profit", 4)     AS "total_profit"
FROM   ranked
WHERE  "rn" = 1
ORDER BY "month" ASC;