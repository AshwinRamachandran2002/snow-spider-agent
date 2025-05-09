SELECT 
    TO_CHAR(
        TO_TIMESTAMP(oi."created_at" / 1000000),      -- micro-seconds → seconds
        'YYYY-MM'
    )                                                AS "year_month",
    SUM(oi."sale_price")                             AS "total_sales",
    SUM(ii."cost")                                   AS "total_cost",
    COUNT(DISTINCT oi."order_id")                    AS "num_complete_orders",
    SUM(oi."sale_price" - ii."cost")                 AS "total_profit",
    CASE 
        WHEN SUM(ii."cost") = 0 THEN NULL
        ELSE ROUND( SUM(oi."sale_price" - ii."cost") / SUM(ii."cost"), 4 )
    END                                              AS "profit_to_cost_ratio"
FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"      oi
JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"           o   ON oi."order_id" = o."order_id"
JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."INVENTORY_ITEMS"  ii  ON oi."inventory_item_id" = ii."id"
JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"         p   ON oi."product_id" = p."id"
WHERE o."status" = 'Complete'
  AND p."category" ILIKE '%Sleep%Lounge%'
  AND o."created_at" >= 1672531200000000        -- 2023-01-01 00:00:00 UTC
  AND o."created_at" <  1704067200000000        -- 2024-01-01 00:00:00 UTC
GROUP BY "year_month"
ORDER BY "year_month";