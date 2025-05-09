SELECT
    DATE_TRUNC('month', TO_TIMESTAMP("o"."created_at" / 1000000))  AS "order_month",
    SUM("oi"."sale_price")                                         AS "total_sales",
    SUM("ii"."cost")                                               AS "total_cost",
    COUNT(DISTINCT "oi"."order_id")                                AS "complete_orders",
    SUM("oi"."sale_price" - "ii"."cost")                           AS "total_profit",
    CASE
        WHEN SUM("ii"."cost") <> 0
        THEN ROUND(SUM("oi"."sale_price" - "ii"."cost") / SUM("ii"."cost"), 4)
        ELSE NULL
    END                                                            AS "profit_to_cost_ratio"
FROM   "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS"       AS "oi"
JOIN   "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDERS"            AS "o"
       ON "oi"."order_id" = "o"."order_id"
JOIN   "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."PRODUCTS"          AS "p"
       ON "oi"."product_id" = "p"."id"
JOIN   "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."INVENTORY_ITEMS"   AS "ii"
       ON "oi"."inventory_item_id" = "ii"."id"
WHERE  "oi"."status" = 'Complete'
  AND  "p"."category" = 'Sleep & Lounge'
  AND  "o"."created_at" BETWEEN 1672531200000000                -- 2023-01-01 00:00:00
                         AND 1704067199000000                -- 2023-12-31 23:59:59
GROUP BY "order_month"
ORDER BY "order_month";