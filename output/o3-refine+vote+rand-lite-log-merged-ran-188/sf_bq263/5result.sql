WITH "order_data" AS (
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP_NTZ("o"."created_at" / 1000000)) AS "month",
        "oi"."order_id",
        "oi"."sale_price",
        "p"."cost"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"       AS "o"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  AS "oi"
          ON "o"."order_id" = "oi"."order_id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"     AS "p"
          ON "oi"."product_id" = "p"."id"
    WHERE "o"."status" = 'Complete'
      AND "p"."category" = 'Sleep & Lounge'
      AND TO_DATE(TO_TIMESTAMP_NTZ("o"."created_at" / 1000000))
            BETWEEN '2023-01-01' AND '2023-12-31'
)

SELECT
    TO_CHAR("month", 'YYYY-MM')                                                                     AS "month",
    SUM("sale_price")                                                                               AS "total_sales",
    SUM("cost")                                                                                     AS "total_cost",
    COUNT(DISTINCT "order_id")                                                                      AS "complete_orders",
    SUM("sale_price") - SUM("cost")                                                                 AS "total_profit",
    ROUND((SUM("sale_price") - SUM("cost")) / NULLIF(SUM("cost"), 0), 4)                            AS "profit_to_cost_ratio"
FROM "order_data"
GROUP BY "month"
ORDER BY "month";