WITH monthly_product_profit AS (
    SELECT
        TO_CHAR(TO_TIMESTAMP_LTZ(oi."created_at", 6), 'YYYY-MM') AS "order_month",
        p."id"                                                   AS "product_id",
        p."name"                                                 AS "product_name",
        SUM(p."cost")                                            AS "total_cost",
        SUM(oi."sale_price" - p."cost")                          AS "total_profit",
        RANK() OVER (
            PARTITION BY TO_CHAR(TO_TIMESTAMP_LTZ(oi."created_at", 6), 'YYYY-MM')
            ORDER BY SUM(oi."sale_price" - p."cost") DESC
        )                                                       AS "profit_rank"
    FROM  "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS"  oi
    JOIN  "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."PRODUCTS"     p
          ON p."id" = oi."product_id"
    WHERE TO_TIMESTAMP_LTZ(oi."created_at", 6) < '2024-01-01'
    GROUP BY
        TO_CHAR(TO_TIMESTAMP_LTZ(oi."created_at", 6), 'YYYY-MM'),
        p."id",
        p."name"
)

SELECT
    "order_month",
    "product_id",
    "product_name",
    "total_cost",
    "total_profit"
FROM   monthly_product_profit
WHERE  "profit_rank" = 1
ORDER BY "order_month";