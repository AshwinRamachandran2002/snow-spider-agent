SELECT
    TO_CHAR(TO_TIMESTAMP(o."created_at" / 1e6), 'YYYY-MM')          AS "month",
    SUM(oi."sale_price")                                            AS "total_sales",
    SUM(p."cost")                                                   AS "total_cost",
    COUNT(DISTINCT oi."order_id")                                   AS "complete_orders",
    SUM(oi."sale_price") - SUM(p."cost")                            AS "total_profit",
    CASE
        WHEN SUM(p."cost") = 0 THEN NULL
        ELSE (SUM(oi."sale_price") - SUM(p."cost")) / SUM(p."cost")
    END                                                             AS "profit_to_cost_ratio"
FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  oi
JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"       o
     ON oi."order_id" = o."order_id"
JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"     p
     ON oi."product_id" = p."id"
WHERE p."category" ILIKE '%Sleep%Lounge%'
  AND o."status" = 'Complete'
  AND oi."status" = 'Complete'
  AND TO_TIMESTAMP(o."created_at" / 1e6) 
        BETWEEN '2023-01-01'::TIMESTAMP AND '2023-12-31 23:59:59'::TIMESTAMP
GROUP BY 1
ORDER BY 1;