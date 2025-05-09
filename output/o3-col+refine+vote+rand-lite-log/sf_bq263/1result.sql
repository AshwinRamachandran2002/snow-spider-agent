SELECT 
       TO_CHAR(TO_TIMESTAMP("oi"."created_at" / 1000000), 'YYYY-MM') AS "month",
       SUM("oi"."sale_price")                                        AS "total_sales",
       SUM("ii"."cost")                                              AS "total_cost",
       COUNT(DISTINCT "oi"."order_id")                               AS "complete_orders",
       SUM("oi"."sale_price" - "ii"."cost")                          AS "total_profit",
       CASE 
            WHEN COALESCE(SUM("ii"."cost"), 0) = 0 
            THEN NULL
            ELSE SUM("oi"."sale_price" - "ii"."cost") / SUM("ii"."cost")
       END                                                           AS "profit_to_cost_ratio"
FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"     "oi"
JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."INVENTORY_ITEMS" "ii"
     ON "ii"."id" = "oi"."inventory_item_id"
JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"        "p"
     ON "p"."id" = "oi"."product_id"
WHERE "p"."category" ILIKE '%Sleep%Lounge%'               -- focus on the Sleep & Lounge category
  AND "oi"."status"  = 'Complete'                         -- only completed orders
  AND "oi"."created_at" BETWEEN 1672531200000000          -- 01-Jan-2023 00:00:00 µs
                          AND 1704067199000000            -- 31-Dec-2023 23:59:59 µs
GROUP BY 1
ORDER BY 1;