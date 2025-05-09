WITH "ORDER_ITEMS_2023" AS (
    SELECT
        oi."order_id",
        oi."sale_price",
        p."cost"                                    AS "product_cost",
        DATE_TRUNC(
            'MONTH',
            TO_TIMESTAMP_NTZ(o."created_at" / 1000000)
        )                                           AS "order_month"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"          oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"               o
          ON oi."order_id" = o."order_id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"             p
          ON oi."product_id" = p."id"
    WHERE o."status" = 'Complete'
      AND oi."status" = 'Complete'
      AND p."category" = 'Sleep & Lounge'
      AND TO_TIMESTAMP_NTZ(o."created_at" / 1000000)
            BETWEEN '2023-01-01'::TIMESTAMP
                AND '2023-12-31 23:59:59'::TIMESTAMP
)
SELECT
    "order_month"                                            AS "month",
    ROUND(SUM("sale_price"), 4)                              AS "total_sales",
    ROUND(SUM("product_cost"), 4)                            AS "total_cost",
    COUNT(DISTINCT "order_id")                               AS "complete_orders",
    ROUND(SUM("sale_price") - SUM("product_cost"), 4)        AS "total_profit",
    ROUND(
        (SUM("sale_price") - SUM("product_cost"))
        / NULLIF(SUM("product_cost"), 0),
        4
    )                                                        AS "profit_to_cost_ratio"
FROM "ORDER_ITEMS_2023"
GROUP BY "order_month"
ORDER BY "order_month";