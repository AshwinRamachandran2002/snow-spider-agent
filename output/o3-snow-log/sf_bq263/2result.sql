SELECT 
       DATE_TRUNC('month', TO_TIMESTAMP(oi."created_at" / 1000000))                          AS "order_month",
       SUM(oi."sale_price")                                                                 AS "total_sales",
       SUM(p."cost")                                                                        AS "total_cost",
       COUNT(DISTINCT oi."order_id")                                                        AS "complete_orders",
       SUM(oi."sale_price" - p."cost")                                                      AS "total_profit",
       CASE 
            WHEN SUM(p."cost") = 0 THEN NULL 
            ELSE SUM(oi."sale_price" - p."cost") / SUM(p."cost") 
       END                                                                                  AS "profit_to_cost_ratio"
FROM   "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS"   oi
JOIN   "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDERS"        o
       ON oi."order_id" = o."order_id"
JOIN   "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."PRODUCTS"      p
       ON oi."product_id" = p."id"
WHERE  oi."status"      = 'Complete'
  AND  o."status"       = 'Complete'
  AND  p."category" ILIKE '%Sleep%Lounge%'
  AND  oi."created_at" BETWEEN 1672531200000000     -- 2023-01-01 00:00:00 UTC
                          AND 1704067199999999     -- 2023-12-31 23:59:59.999999 UTC
GROUP BY 1
ORDER BY 1;