SELECT
    DATE_TRUNC('month', TO_TIMESTAMP("oi"."created_at" / 1000000)) AS "month",
    ROUND(SUM("oi"."sale_price"), 4)                              AS "total_sales",
    ROUND(SUM("p"."cost"), 4)                                     AS "total_cost",
    COUNT(DISTINCT "oi"."order_id")                               AS "complete_orders",
    ROUND(SUM("oi"."sale_price" - "p"."cost"), 4)                 AS "total_profit",
    ROUND(
        CASE
            WHEN SUM("p"."cost") = 0 THEN NULL
            ELSE SUM("oi"."sale_price" - "p"."cost") / SUM("p"."cost")
        END,
    4)                                                            AS "profit_to_cost_ratio"
FROM "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS" AS "oi"
JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDERS"      AS "o"
     ON "oi"."order_id" = "o"."order_id"
JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."PRODUCTS"    AS "p"
     ON "oi"."product_id" = "p"."id"
WHERE "p"."category" = 'Sleep & Lounge'
  AND "oi"."status"  = 'Complete'
  AND "o"."status"   = 'Complete'
  AND TO_TIMESTAMP("oi"."created_at" / 1000000) >= '2023-01-01'::TIMESTAMP
  AND TO_TIMESTAMP("oi"."created_at" / 1000000) <  '2024-01-01'::TIMESTAMP
GROUP BY 1
ORDER BY 1;