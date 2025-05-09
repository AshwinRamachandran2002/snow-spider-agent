WITH "ORDERS_2023" AS (
    SELECT
        DATE_TRUNC(
            'month',
            TO_TIMESTAMP_LTZ("O"."created_at" / 1000000)
        )                               AS "month_start",
        "OI"."sale_price"               AS "sale_price",
        "P"."cost"                      AS "product_cost",
        "O"."order_id"                  AS "order_id"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"       AS "O"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  AS "OI"
        ON "OI"."order_id" = "O"."order_id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"     AS "P"
        ON "P"."id" = "OI"."product_id"
    WHERE "O"."status"      = 'Complete'
      AND "OI"."status"     = 'Complete'
      AND "P"."category"    = 'Sleep & Lounge'
      AND TO_TIMESTAMP_LTZ("O"."created_at" / 1000000)
          BETWEEN '2023-01-01' AND '2023-12-31 23:59:59'
)

SELECT
    TO_CHAR("month_start", 'YYYY-MM')                                    AS "month",
    ROUND(SUM("sale_price"), 4)                                          AS "total_sales",
    ROUND(SUM("product_cost"), 4)                                        AS "total_cost",
    COUNT(DISTINCT "order_id")                                           AS "complete_orders",
    ROUND(SUM("sale_price") - SUM("product_cost"), 4)                    AS "total_profit",
    CASE 
        WHEN SUM("product_cost") = 0 THEN NULL
        ELSE ROUND((SUM("sale_price") - SUM("product_cost")) /
                   SUM("product_cost"), 4)
    END                                                                  AS "profit_to_cost_ratio"
FROM "ORDERS_2023"
GROUP BY "month_start"
ORDER BY "month_start";