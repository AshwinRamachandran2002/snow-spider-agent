SELECT
    TO_CHAR(DATE_TRUNC('month', TO_TIMESTAMP("oi"."created_at" / 1000000)), 'YYYY-MM')                AS "MONTH",
    ROUND(SUM("oi"."sale_price"), 4)                                                                 AS "TOTAL_SALES",
    ROUND(SUM("p"."cost"), 4)                                                                        AS "TOTAL_COST",
    COUNT(DISTINCT "oi"."order_id")                                                                  AS "COMPLETE_ORDERS",
    ROUND(SUM("oi"."sale_price") - SUM("p"."cost"), 4)                                               AS "TOTAL_PROFIT",
    ROUND((SUM("oi"."sale_price") - SUM("p"."cost")) / NULLIF(SUM("p"."cost"), 0), 4)                AS "PROFIT_TO_COST_RATIO"
FROM
    THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"         AS "oi"
JOIN
    THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"            AS "p"
        ON "oi"."product_id" = "p"."id"
WHERE
        "oi"."status" = 'Complete'
    AND "p"."category" = 'Sleep & Lounge'
    AND TO_DATE(TO_TIMESTAMP("oi"."created_at" / 1000000)) 
        BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY
    TO_CHAR(DATE_TRUNC('month', TO_TIMESTAMP("oi"."created_at" / 1000000)), 'YYYY-MM')
ORDER BY
    "MONTH";