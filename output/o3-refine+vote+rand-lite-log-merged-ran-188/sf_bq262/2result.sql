WITH order_level AS (   -- revenue / cost calculated at order‑category level
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP("o"."created_at" / 1000000))                AS "month_start",
        "p"."category"                                                               AS "product_category",
        "o"."order_id"                                                               AS "order_id",
        SUM("oi"."sale_price")                                                       AS "order_revenue",
        SUM("p"."cost")                                                              AS "order_cost"
    FROM "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS"      AS "oi"
    JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDERS"           AS "o"
          ON "oi"."order_id" = "o"."order_id"
    JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."PRODUCTS"         AS "p"
          ON "oi"."product_id" = "p"."id"
    WHERE DATE_TRUNC('month', TO_TIMESTAMP("o"."created_at" / 1000000))
          BETWEEN '2019-06-01' AND '2019-12-01'        -- keep Jun‑Dec 2019
    GROUP BY
        "month_start",
        "product_category",
        "o"."order_id"
),
month_category AS (     -- aggregate to month & category
    SELECT
        "month_start",
        "product_category",
        COUNT(DISTINCT "order_id")                              AS "total_orders",
        SUM("order_revenue")                                    AS "total_revenue",
        SUM("order_revenue" - "order_cost")                     AS "total_profit"
    FROM order_level
    GROUP BY
        "month_start",
        "product_category"
),
with_growth AS (        -- get previous‑month values for MoM growth
    SELECT
        "month_start",
        "product_category",
        "total_orders",
        "total_revenue",
        "total_profit",
        LAG("total_orders")  OVER (PARTITION BY "product_category" ORDER BY "month_start") AS "prev_orders",
        LAG("total_revenue") OVER (PARTITION BY "product_category" ORDER BY "month_start") AS "prev_revenue",
        LAG("total_profit")  OVER (PARTITION BY "product_category" ORDER BY "month_start") AS "prev_profit"
    FROM month_category
)
SELECT
    TO_CHAR("month_start", 'YYYY-MM')                                               AS "month",
    "product_category",
    "total_orders",
    "total_revenue",
    "total_profit",
    ROUND( ("total_orders"  - "prev_orders")  / NULLIF("prev_orders",  0), 4)       AS "orders_mom_growth",
    ROUND( ("total_revenue" - "prev_revenue") / NULLIF("prev_revenue", 0), 4)       AS "revenue_mom_growth",
    ROUND( ("total_profit"  - "prev_profit")  / NULLIF("prev_profit",  0), 4)       AS "profit_mom_growth"
FROM with_growth
WHERE "month_start" >= '2019-07-01'                 -- omit June rows from final output
ORDER BY
    "month_start",
    "product_category";