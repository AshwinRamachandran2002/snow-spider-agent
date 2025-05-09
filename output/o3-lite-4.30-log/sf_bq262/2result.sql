WITH month_stats AS (
    SELECT
        TO_CHAR(
            DATE_TRUNC('month', TO_TIMESTAMP("o"."created_at" / 1000000)),
            'YYYY-MM'
        )                                                          AS "month",
        "p"."category"                                             AS "product_category",
        COUNT(DISTINCT "o"."order_id")                             AS "total_orders",
        SUM("oi"."sale_price")                                     AS "total_revenue",
        SUM("oi"."sale_price" - "p"."cost")                        AS "total_profit"
    FROM  "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS"  AS "oi"
    JOIN  "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDERS"       AS "o"
          ON "o"."order_id" = "oi"."order_id"
    JOIN  "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."PRODUCTS"     AS "p"
          ON "p"."id" = "oi"."product_id"
    WHERE TO_TIMESTAMP("o"."created_at" / 1000000)
              BETWEEN '2019-06-01' AND '2019-12-31 23:59:59'
    GROUP BY 1, 2
),
jun AS (   -- June 2019 baseline
    SELECT
        "product_category",
        "total_orders"   AS "orders_jun",
        "total_revenue"  AS "revenue_jun",
        "total_profit"   AS "profit_jun"
    FROM   month_stats
    WHERE  "month" = '2019-06'
)

SELECT
    "ms"."month",
    "ms"."product_category",
    "ms"."total_orders",
    "ms"."total_revenue",
    "ms"."total_profit",
    ROUND( ("ms"."total_orders"  - "j"."orders_jun")  / NULLIF("j"."orders_jun",  0), 4)  AS "orders_mom_growth",
    ROUND( ("ms"."total_revenue" - "j"."revenue_jun") / NULLIF("j"."revenue_jun", 0), 4)  AS "revenue_mom_growth",
    ROUND( ("ms"."total_profit"  - "j"."profit_jun")  / NULLIF("j"."profit_jun",  0), 4)  AS "profit_mom_growth"
FROM   month_stats AS "ms"
JOIN   jun          AS "j"
       ON "ms"."product_category" = "j"."product_category"
WHERE  "ms"."month" <> '2019-06'          -- omit June from final output
ORDER  BY
       "ms"."month" ASC,
       "ms"."product_category" ASC;