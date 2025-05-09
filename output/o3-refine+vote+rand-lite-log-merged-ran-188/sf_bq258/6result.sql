/*  Monthly performance report by product category
    – only “Complete” orders delivered before 2022-01-01
    – revenue / order counts / MoM growth
    – cost, profit and profit-to-cost ratio                                    */

WITH completed_monthly AS (
    SELECT
        p."category" AS "category",
        DATE_TRUNC(
            'month',
            TO_TIMESTAMP_LTZ(o."delivered_at" / 1000000)      -- convert µs → sec → timestamp
        )                AS "month_start",
        SUM(oi."sale_price")          AS "revenue",
        COUNT(DISTINCT oi."order_id") AS "completed_orders",
        SUM(p."cost")                 AS "total_cost"
    FROM  THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  oi
    JOIN  THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"       o  ON oi."order_id" = o."order_id"
    JOIN  THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"     p  ON oi."product_id" = p."id"
    WHERE o."status" = 'Complete'
      AND o."delivered_at" IS NOT NULL
      AND o."delivered_at" < 1640995200000000                -- 2022-01-01 in µs
    GROUP BY
        p."category",
        DATE_TRUNC('month', TO_TIMESTAMP_LTZ(o."delivered_at" / 1000000))
),

lagged AS (
    SELECT
        cm.*,
        LAG(cm."revenue") OVER (PARTITION BY cm."category" ORDER BY cm."month_start")  AS "prev_revenue",
        LAG(cm."completed_orders") OVER (PARTITION BY cm."category" ORDER BY cm."month_start") AS "prev_orders"
    FROM completed_monthly cm
)

SELECT
    "category",
    "month_start",
    "revenue",
    "completed_orders",
    /* month-over-month % growth for revenue */
    ROUND(
        CASE
            WHEN "prev_revenue" IS NULL OR "prev_revenue" = 0 THEN NULL
            ELSE ("revenue" - "prev_revenue") / "prev_revenue" * 100
        END, 4
    ) AS "revenue_mom_growth_pct",
    /* month-over-month % growth for completed orders */
    ROUND(
        CASE
            WHEN "prev_orders" IS NULL OR "prev_orders" = 0 THEN NULL
            ELSE ("completed_orders" - "prev_orders") / "prev_orders" * 100
        END, 4
    ) AS "orders_mom_growth_pct",
    "total_cost",
    ("revenue" - "total_cost")                                            AS "profit",
    ("revenue" - "total_cost") / NULLIF("total_cost", 0)                  AS "profit_to_cost_ratio"
FROM lagged
ORDER BY
    "category",
    "month_start";