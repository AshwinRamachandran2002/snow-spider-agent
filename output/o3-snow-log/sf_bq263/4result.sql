/* Month-by-month Sleep & Lounge performance for calendar year-2023 */
SELECT
    TO_CHAR(
        TO_TIMESTAMP(oi."created_at" / 1000000),        /* microseconds → timestamp */
        'YYYY-MM'                                       /* year-month bucket        */
    )                                         AS "month",
    SUM(oi."sale_price")                      AS "total_sales",
    SUM(p."cost")                             AS "total_cost",
    COUNT(DISTINCT oi."order_id")             AS "complete_orders",
    SUM(oi."sale_price") - SUM(p."cost")      AS "total_profit",
    (SUM(oi."sale_price") - SUM(p."cost"))
      / NULLIF(SUM(p."cost"), 0)              AS "profit_to_cost_ratio"
FROM   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  oi
JOIN   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"      p
       ON  p."id"        = oi."product_id"
JOIN   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"        o
       ON  o."order_id"  = oi."order_id"
WHERE  p."category" ILIKE '%Sleep%Lounge%'     -- focus category
  AND  oi."status"   = 'Complete'              -- line-item completed
  AND  o."status"    = 'Complete'              -- order completed
  AND  TO_TIMESTAMP(oi."created_at" / 1000000) >= '2023-01-01'
  AND  TO_TIMESTAMP(oi."created_at" / 1000000) <  '2024-01-01'
GROUP  BY TO_CHAR(TO_TIMESTAMP(oi."created_at" / 1000000), 'YYYY-MM')
ORDER  BY "month";