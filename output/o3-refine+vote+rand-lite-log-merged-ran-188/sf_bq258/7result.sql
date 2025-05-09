/*  Monthly performance report (per product category)
    – Only “Complete” order-items that were delivered before 2022-01-01
*/

WITH monthly AS (
    SELECT
        TO_CHAR(TO_TIMESTAMP(oi."delivered_at" / 1e6), 'YYYY-MM')          AS "year_month",
        p."category"                                                      AS "category",
        SUM(oi."sale_price")                                              AS "total_revenue",
        COUNT(DISTINCT oi."order_id")                                     AS "completed_orders",
        SUM(p."cost")                                                     AS "total_cost",
        SUM(oi."sale_price") - SUM(p."cost")                              AS "profit"
    FROM "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS"  oi
    JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."PRODUCTS"     p
      ON oi."product_id" = p."id"
    WHERE oi."status"        = 'Complete'
      AND oi."delivered_at" IS NOT NULL
      AND oi."delivered_at"  < 1640995200000000      -- 2022-01-01 00:00:00 µs
    GROUP BY
        TO_CHAR(TO_TIMESTAMP(oi."delivered_at" / 1e6), 'YYYY-MM'),
        p."category"
),

ordered AS (
    SELECT
        m.*,
        LAG(m."total_revenue")    OVER (PARTITION BY m."category" ORDER BY m."year_month") AS "prev_revenue",
        LAG(m."completed_orders") OVER (PARTITION BY m."category" ORDER BY m."year_month") AS "prev_orders"
    FROM monthly m
)

SELECT
    "year_month",
    "category",
    "total_revenue",
    "completed_orders",
    "total_cost",
    "profit",
    /* Month-over-month growth calculations */
    ROUND(100 * ( "total_revenue"   - "prev_revenue")
              / NULLIF("prev_revenue",0), 2)                               AS "MoM_revenue_growth_pct",
    ROUND(100 * ( "completed_orders" - "prev_orders")
              / NULLIF("prev_orders",0), 2)                                AS "MoM_orders_growth_pct",
    /* Profitability ratio */
    ROUND("profit" / NULLIF("total_cost",0), 2)                            AS "profit_to_cost_ratio"
FROM ordered
ORDER BY
    "category",
    "year_month";