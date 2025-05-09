/*  Monthly category‑level P&L with MoM growth               */
/*  – Only “Complete” order‑items delivered before 2022‑01‑01 */

WITH base AS (
    SELECT
        DATE_TRUNC(
            'month',
            TO_TIMESTAMP_NTZ("oi"."delivered_at" / 1000000)
        )                                       AS "month",
        "p"."category"                          AS "category",
        SUM("oi"."sale_price")                  AS "total_revenue",
        COUNT(DISTINCT "oi"."order_id")         AS "total_completed_orders",
        SUM("p"."cost")                         AS "total_cost"
    FROM   "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS"  AS "oi"
    JOIN   "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."PRODUCTS"     AS "p"
           ON "oi"."product_id" = "p"."id"
    WHERE  "oi"."status" = 'Complete'
      AND  "oi"."delivered_at" < 1640995200000000      -- 2022‑01‑01 (µs)
    GROUP  BY 1, 2
)

SELECT
    "month",
    "category",
    "total_revenue",
    "total_completed_orders",
    "total_cost",
    /* profitability */
    ("total_revenue" - "total_cost")                          AS "profit",
    ("total_revenue" - "total_cost")
        / NULLIF("total_cost", 0)                             AS "profit_to_cost_ratio",
    /* MoM growth – revenue */
    CASE
        WHEN LAG("total_revenue") OVER (PARTITION BY "category" ORDER BY "month") IS NULL
             OR LAG("total_revenue") OVER (PARTITION BY "category" ORDER BY "month") = 0
        THEN NULL
        ELSE ( "total_revenue"
             - LAG("total_revenue") OVER (PARTITION BY "category" ORDER BY "month") )
             / LAG("total_revenue") OVER (PARTITION BY "category" ORDER BY "month")
    END                                                      AS "mom_revenue_growth",
    /* MoM growth – orders */
    CASE
        WHEN LAG("total_completed_orders") OVER (PARTITION BY "category" ORDER BY "month") IS NULL
             OR LAG("total_completed_orders") OVER (PARTITION BY "category" ORDER BY "month") = 0
        THEN NULL
        ELSE ( "total_completed_orders"
             - LAG("total_completed_orders") OVER (PARTITION BY "category" ORDER BY "month") )
             / LAG("total_completed_orders") OVER (PARTITION BY "category" ORDER BY "month")
    END                                                      AS "mom_orders_growth"
FROM   base
ORDER  BY "category", "month";