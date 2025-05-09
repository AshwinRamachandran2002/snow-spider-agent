WITH "filtered" AS (
    SELECT
        DATE_TRUNC(
            'month',
            TO_TIMESTAMP("oi"."created_at" / 1000000)
        )                                   AS "month",
        "oi"."order_id"                     AS "order_id",
        "oi"."sale_price"                   AS "sale_price",
        "p"."cost"                          AS "unit_cost"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  AS "oi"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"     AS "p"
          ON "oi"."product_id" = "p"."id"
    WHERE "oi"."status" = 'Complete'
      AND "p"."category" = 'Sleep & Lounge'
      AND TO_TIMESTAMP("oi"."created_at" / 1000000)
            BETWEEN '2023-01-01' AND '2023-12-31 23:59:59.999'
)

SELECT
    TO_CHAR("month", 'YYYY-MM')                                     AS "month",
    ROUND(SUM("sale_price"), 4)                                     AS "total_sales",
    ROUND(SUM("unit_cost"), 4)                                      AS "total_cost",
    COUNT(DISTINCT "order_id")                                      AS "num_complete_orders",
    ROUND(SUM("sale_price") - SUM("unit_cost"), 4)                  AS "total_profit",
    ROUND(
        CASE WHEN SUM("unit_cost") <> 0
             THEN (SUM("sale_price") - SUM("unit_cost")) / SUM("unit_cost")
        END, 4
    )                                                               AS "profit_to_cost_ratio"
FROM "filtered"
GROUP BY "month"
ORDER BY "month";