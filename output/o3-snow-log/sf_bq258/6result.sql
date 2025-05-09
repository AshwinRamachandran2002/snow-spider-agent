/* -------------------------------------------------------
   Monthly performance report by product category
   – only orders whose items
     • have status = 'Complete'
     • were delivered before 2022-01-01
--------------------------------------------------------*/
WITH completed_delivered AS (       -- 1. isolate the relevant order-item rows
    SELECT
        oi."order_id",
        oi."sale_price",
        oi."product_id",
        p."category",
        p."cost"                        AS product_cost,
        TO_TIMESTAMP_NTZ(oi."delivered_at" / 1000000) AS delivered_ts   -- micro-seconds → timestamp
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"     p
          ON oi."product_id" = p."id"
    WHERE oi."status" = 'Complete'
      AND oi."delivered_at" IS NOT NULL
      AND TO_TIMESTAMP_NTZ(oi."delivered_at" / 1000000) < '2022-01-01'
), 

monthly_agg AS (                    -- 2. aggregate by category & month
    SELECT
        "category",
        DATE_TRUNC('month', delivered_ts)                AS month_start,
        SUM("sale_price")                                AS total_revenue,
        COUNT(DISTINCT "order_id")                       AS total_orders,
        SUM(product_cost)                                AS total_cost,
        SUM("sale_price") - SUM(product_cost)            AS total_profit,
        (SUM("sale_price") - SUM(product_cost))
            / NULLIF(SUM(product_cost), 0)               AS profit_to_cost_ratio
    FROM completed_delivered
    GROUP BY "category", month_start
), 

with_growth AS (                   -- 3. add month-over-month growth using window functions
    SELECT
        "category",
        month_start,
        total_revenue,
        total_orders,
        total_cost,
        total_profit,
        profit_to_cost_ratio,
        LAG(total_revenue) OVER (PARTITION BY "category" ORDER BY month_start) AS prev_revenue,
        LAG(total_orders)  OVER (PARTITION BY "category" ORDER BY month_start) AS prev_orders
    FROM monthly_agg
)

SELECT
    "category",
    TO_CHAR(month_start, 'YYYY-MM')                                 AS year_month,
    total_revenue,
    total_orders,
    ROUND((total_revenue - prev_revenue) / NULLIF(prev_revenue, 0) * 100, 4)
                                                                     AS revenue_mom_growth_pct,
    ROUND((total_orders  - prev_orders)  / NULLIF(prev_orders,  0) * 100, 4)
                                                                     AS orders_mom_growth_pct,
    total_cost,
    total_profit,
    profit_to_cost_ratio
FROM with_growth
ORDER BY "category", month_start NULLS LAST;