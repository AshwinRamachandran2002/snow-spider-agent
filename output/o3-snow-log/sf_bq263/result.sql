SELECT 
    TO_CHAR(TO_TIMESTAMP(oi."created_at" / 1000000), 'YYYY-MM')      AS "month",
    SUM(oi."sale_price")                                             AS "total_sales",
    SUM(p."cost")                                                    AS "total_cost",
    COUNT(DISTINCT o."order_id")                                     AS "num_complete_orders",
    SUM(oi."sale_price" - p."cost")                                  AS "total_profit",
    ROUND(
        SUM(oi."sale_price" - p."cost") / NULLIF(SUM(p."cost"), 0),
        4
    )                                                                AS "profit_to_cost_ratio"
FROM "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS"    oi
JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDERS"         o
      ON oi."order_id" = o."order_id"
JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."PRODUCTS"       p
      ON oi."product_id" = p."id"
WHERE p."category" = 'Sleep & Lounge'
  AND o."status"    = 'Complete'
  AND oi."created_at" BETWEEN 1672531200000000  -- 2023-01-01 00:00:00
                         AND 1704067199000000  -- 2023-12-31 23:59:59
GROUP BY TO_CHAR(TO_TIMESTAMP(oi."created_at" / 1000000), 'YYYY-MM')
ORDER BY "month";