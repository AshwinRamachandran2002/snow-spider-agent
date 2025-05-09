SELECT
    TO_CHAR(TO_TIMESTAMP("oi"."created_at" / 1e6), 'YYYY-MM') AS "month",
    ROUND(SUM("oi"."sale_price"), 4)                          AS "total_sales",
    ROUND(SUM("p"."cost"), 4)                                 AS "total_cost",
    COUNT(DISTINCT "oi"."order_id")                           AS "complete_orders",
    ROUND(SUM("oi"."sale_price" - "p"."cost"), 4)             AS "total_profit",
    CASE 
        WHEN SUM("p"."cost") = 0 THEN NULL
        ELSE ROUND(SUM("oi"."sale_price" - "p"."cost") / SUM("p"."cost"), 4)
    END                                                       AS "profit_to_cost_ratio"
FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS AS "oi"
JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.PRODUCTS    AS "p"
     ON "p"."id" = "oi"."product_id"
JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS      AS "o"
     ON "o"."order_id" = "oi"."order_id"
WHERE "p"."category"  = 'Sleep & Lounge'
  AND "oi"."status"   = 'Complete'
  AND "o"."status"    = 'Complete'
  AND "oi"."created_at" BETWEEN 1672531200000000  -- 2023‑01‑01 00:00:00
                           AND   1704067199999999  -- 2023‑12‑31 23:59:59
GROUP BY TO_CHAR(TO_TIMESTAMP("oi"."created_at" / 1e6), 'YYYY-MM')
ORDER BY "month";