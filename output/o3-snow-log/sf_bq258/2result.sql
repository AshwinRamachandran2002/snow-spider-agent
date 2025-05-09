/* Monthly performance by product category for orders that
   are 1) in status 'Complete' and 2) were delivered before 2022-01-01.
   Report includes revenue, order count, MoM % growth, cost, profit
   and profit-to-cost ratio. */

WITH base AS (   -- 1. Aggregate figures per category & month
    SELECT
        p."category"                                                 AS "product_category",
        DATE_TRUNC(
            'month',
            TO_TIMESTAMP_NTZ(oi."delivered_at" / 1000000)
        )                                                            AS "month_start",
        SUM(oi."sale_price")                                         AS "total_revenue",
        COUNT(DISTINCT oi."order_id")                                AS "completed_orders",
        SUM(p."cost")                                                AS "total_cost"
    FROM  THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  oi
    JOIN  THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"     p
          ON oi."product_id" = p."id"
    WHERE oi."status"       = 'Complete'
      AND oi."delivered_at" IS NOT NULL
      AND oi."delivered_at" < 1640995200000000      -- 2022-01-01 in µs
    GROUP BY
        p."category",
        DATE_TRUNC('month', TO_TIMESTAMP_NTZ(oi."delivered_at" / 1000000))
),

calc AS (          -- 2. Add profit and previous-month values
    SELECT
        "product_category",
        "month_start",
        "total_revenue",
        "completed_orders",
        "total_cost",
        ("total_revenue" - "total_cost")                             AS "profit",
        CASE WHEN "total_cost" <> 0
             THEN ("total_revenue" - "total_cost") / "total_cost"
        END                                                         AS "profit_to_cost_ratio",
        LAG("total_revenue")    OVER (PARTITION BY "product_category"
                                      ORDER BY "month_start")       AS "prev_revenue",
        LAG("completed_orders") OVER (PARTITION BY "product_category"
                                      ORDER BY "month_start")       AS "prev_orders"
    FROM base
)

SELECT                   -- 3. Final report
    "product_category",
    "month_start",
    "total_revenue",
    "completed_orders",
    ROUND(
        CASE WHEN "prev_revenue" IS NULL OR "prev_revenue" = 0
             THEN NULL
             ELSE ("total_revenue" - "prev_revenue") / "prev_revenue"
        END , 4)                                             AS "rev_mom_growth",
    ROUND(
        CASE WHEN "prev_orders" IS NULL OR "prev_orders" = 0
             THEN NULL
             ELSE ("completed_orders" - "prev_orders") / "prev_orders"
        END , 4)                                             AS "orders_mom_growth",
    "total_cost",
    "profit",
    ROUND("profit_to_cost_ratio", 4)                         AS "profit_to_cost_ratio"
FROM calc
ORDER BY
    "product_category",
    "month_start";