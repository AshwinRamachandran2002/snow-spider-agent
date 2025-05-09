SELECT
    TO_CHAR(
        DATE_TRUNC('month', TO_TIMESTAMP("o"."created_at" / 1000000)),
        'YYYY-MM'
    )                                           AS "month",
    SUM("oi"."sale_price")                      AS "total_sales",
    SUM("p"."cost")                             AS "total_cost",
    COUNT(DISTINCT "o"."order_id")              AS "complete_orders",
    SUM("oi"."sale_price") - SUM("p"."cost")    AS "total_profit",
    CASE
        WHEN SUM("p"."cost") <> 0 THEN
             ROUND(
                 (SUM("oi"."sale_price") - SUM("p"."cost")) / SUM("p"."cost"),
                 4
             )
    END                                         AS "profit_to_cost_ratio"
FROM   "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS"   AS "oi"
JOIN   "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDERS"        AS "o"
       ON "oi"."order_id" = "o"."order_id"
JOIN   "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."PRODUCTS"      AS "p"
       ON "oi"."product_id" = "p"."id"
WHERE  "o"."status"      = 'Complete'
  AND  "oi"."status"     = 'Complete'
  AND  "p"."category"    = 'Sleep & Lounge'
  AND  TO_TIMESTAMP("o"."created_at" / 1000000) >= '2023-01-01'
  AND  TO_TIMESTAMP("o"."created_at" / 1000000) <  '2024-01-01'
GROUP  BY DATE_TRUNC('month', TO_TIMESTAMP("o"."created_at" / 1000000))
ORDER  BY DATE_TRUNC('month', TO_TIMESTAMP("o"."created_at" / 1000000));