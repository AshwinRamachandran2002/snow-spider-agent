WITH filtered AS (
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP_NTZ("o"."created_at" / 1000000))  AS "month",
        "oi"."sale_price"                                                  AS "sale_price",
        "p"."cost"                                                         AS "cost",
        "o"."order_id"                                                     AS "order_id"
    FROM "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS"        AS "oi"
    JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDERS"             AS "o"
          ON "oi"."order_id" = "o"."order_id"
    JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."PRODUCTS"           AS "p"
          ON "oi"."product_id" = "p"."id"
    WHERE "p"."category" = 'Sleep & Lounge'
      AND "oi"."status" = 'Complete'
      AND "o"."status"  = 'Complete'
      AND TO_DATE(TO_TIMESTAMP_NTZ("o"."created_at" / 1000000))
            BETWEEN '2023-01-01' AND '2023-12-31'
)

SELECT
    "month",
    ROUND(SUM("sale_price"), 4)                                       AS "total_sales",
    ROUND(SUM("cost"), 4)                                             AS "total_cost",
    COUNT(DISTINCT "order_id")                                        AS "complete_orders",
    ROUND(SUM("sale_price") - SUM("cost"), 4)                         AS "total_profit",
    ROUND(
        (SUM("sale_price") - SUM("cost")) / NULLIF(SUM("cost"), 0), 4
    )                                                                 AS "profit_to_cost_ratio"
FROM filtered
GROUP BY "month"
ORDER BY "month" ASC;