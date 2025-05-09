SELECT
    TO_CHAR(
        DATE_TRUNC(
            'month',
            TO_TIMESTAMP(o."created_at" / 1000000)
        ),
        'YYYY-MM'
    )                                                   AS "month",
    ROUND(SUM(oi."sale_price"), 4)                     AS "total_sales",
    ROUND(SUM(p."cost"), 4)                            AS "total_cost",
    COUNT(DISTINCT o."order_id")                       AS "complete_orders",
    ROUND(SUM(oi."sale_price") - SUM(p."cost"), 4)     AS "total_profit",
    ROUND(
        (SUM(oi."sale_price") - SUM(p."cost"))
        / NULLIF(SUM(p."cost"), 0),
        4
    )                                                  AS "profit_to_cost_ratio"
FROM
    THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"        o
JOIN
    THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"   oi
        ON oi."order_id" = o."order_id"
JOIN
    THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"      p
        ON p."id" = oi."product_id"
WHERE
        o."status" = 'Complete'
    AND p."category" = 'Sleep & Lounge'
    AND TO_TIMESTAMP(o."created_at" / 1000000) >= '2023-01-01'::DATE
    AND TO_TIMESTAMP(o."created_at" / 1000000) <  '2024-01-01'::DATE
GROUP BY
    1
ORDER BY
    "month";