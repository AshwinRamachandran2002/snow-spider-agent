SELECT
    TO_CHAR(
        DATE_TRUNC(
            'month',
            TO_TIMESTAMP_NTZ(o."created_at" / 1000000)
        ),
        'YYYY-MM'
    )                                                         AS "month",
    SUM(oi."sale_price")                                      AS "total_sales",
    SUM(p."cost")                                             AS "total_cost",
    COUNT(DISTINCT oi."order_id")                             AS "complete_orders",
    SUM(oi."sale_price" - p."cost")                           AS "total_profit",
    CASE 
        WHEN SUM(p."cost") <> 0 
        THEN SUM(oi."sale_price" - p."cost") / SUM(p."cost") 
    END                                                       AS "profit_to_cost_ratio"
FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS  oi
JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS       o
  ON oi."order_id" = o."order_id"
JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.PRODUCTS     p
  ON oi."product_id" = p."id"
WHERE o."status" = 'Complete'
  AND o."created_at" BETWEEN 1672444800000000         -- 01-Jan-2023 00:00:00
                         AND 1704067199000000         -- 31-Dec-2023 23:59:59
  AND p."category" ILIKE '%Sleep%Lounge%'             -- focus on "Sleep & Lounge"
GROUP BY
    "month"
ORDER BY
    "month";