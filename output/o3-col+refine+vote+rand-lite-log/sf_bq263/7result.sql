SELECT 
    TO_CHAR(TO_TIMESTAMP(o."created_at" / 1e6), 'YYYY-MM')           AS "month",
    SUM(oi."sale_price")                                             AS "total_sales",
    SUM(p."cost")                                                    AS "total_cost",
    COUNT(DISTINCT o."order_id")                                     AS "num_complete_orders",
    SUM(oi."sale_price") - SUM(p."cost")                             AS "total_profit",
    ROUND(
          (SUM(oi."sale_price") - SUM(p."cost"))
          / NULLIF(SUM(p."cost"), 0),
          4
    )                                                                AS "profit_to_cost_ratio"
FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"        o
JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"   oi
     ON o."order_id" = oi."order_id"
JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"      p
     ON oi."product_id" = p."id"
WHERE p."category" = 'Sleep & Lounge'                  -- focus category
  AND o."status"  = 'Complete'                        -- only completed orders
  AND o."created_at" >= 1672531200000000              -- 2023-01-01 00:00:00 UTC
  AND o."created_at" <  1704067200000000              -- 2024-01-01 00:00:00 UTC (exclusive)
GROUP BY 1
ORDER BY 1;