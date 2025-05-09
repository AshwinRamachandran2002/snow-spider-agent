SELECT
    TO_CHAR(
        DATE_TRUNC('month',
            TO_TIMESTAMP_NTZ("o"."created_at" / 1000000)   -- micro‑seconds → seconds
        ),
        'YYYY-MM'
    )                                                   AS "month",
    ROUND(SUM("oi"."sale_price"), 4)                    AS "total_sales",
    ROUND(SUM("p"."cost"), 4)                           AS "total_cost",
    COUNT(DISTINCT "o"."order_id")                      AS "complete_orders",
    ROUND(SUM("oi"."sale_price") - SUM("p"."cost"), 4)  AS "total_profit",
    ROUND(
        (SUM("oi"."sale_price") - SUM("p"."cost"))
        / NULLIF(SUM("p"."cost"), 0),                   -- avoid division by zero
        4
    )                                                   AS "profit_to_cost_ratio"
FROM
    "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDERS"        AS "o"
JOIN
    "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS"   AS "oi"
        ON "o"."order_id" = "oi"."order_id"
JOIN
    "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."PRODUCTS"      AS "p"
        ON "oi"."product_id" = "p"."id"
WHERE
        "o"."status" = 'Complete'
    AND "oi"."status" = 'Complete'
    AND "p"."category" = 'Sleep & Lounge'
    AND TO_DATE(TO_TIMESTAMP_NTZ("o"."created_at" / 1000000))
        BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY
    DATE_TRUNC('month', TO_TIMESTAMP_NTZ("o"."created_at" / 1000000))
ORDER BY
    DATE_TRUNC('month', TO_TIMESTAMP_NTZ("o"."created_at" / 1000000));