/*  Month-by-month 2023 performance of the “Sleep & Lounge” category  */
SELECT
       TO_CHAR( TO_TIMESTAMP( o."created_at" / 1000000 ), 'YYYY-MM')          AS "month_2023",
       COUNT( DISTINCT o."order_id")                                         AS "complete_orders",
       SUM( oi."sale_price")                                                 AS "total_sales",
       SUM( p."cost")                                                        AS "total_cost",
       SUM( oi."sale_price" - p."cost")                                      AS "total_profit",
       ROUND(
             NULLIF( SUM( oi."sale_price" - p."cost"), 0 )
             / NULLIF( SUM( p."cost"), 0 ),
             4
       )                                                                     AS "profit_to_cost_ratio"
FROM   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"        o
JOIN   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"   oi
       ON  oi."order_id" = o."order_id"
JOIN   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"      p
       ON  p."id" = oi."product_id"
WHERE  o."status"  = 'Complete'                       -- order must be complete
  AND  oi."status" = 'Complete'                       -- order-item must be complete
  AND  p."category" ILIKE '%Sleep%Lounge%'            -- focus on Sleep & Lounge items
  AND  o."created_at" BETWEEN 1672531200000000        -- 2023-01-01 00:00:00 µs
                       AND     1704067199000000       -- 2023-12-31 23:59:59 µs
GROUP  BY 1
ORDER  BY 1;