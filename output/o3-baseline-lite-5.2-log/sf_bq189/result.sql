WITH completed_items AS (   -- all order‑items that ended in “Complete”
    SELECT
        oi."order_id",
        p."category",
        DATE_TRUNC(
            'month',
            TO_TIMESTAMP_LTZ(oi."created_at"/1000000)
        )                                     AS month_start,
        oi."sale_price"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"   oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"      p
          ON oi."product_id" = p."id"
    WHERE oi."status" = 'Complete'
),

monthly_stats AS (         -- one row per category / month
    SELECT
        "category",
        month_start,
        COUNT(DISTINCT "order_id")       AS orders_cnt,
        SUM("sale_price")                AS revenue
    FROM completed_items
    GROUP BY "category", month_start
),

add_prev AS (              -- bring in previous‑month values
    SELECT
        *,
        LAG(orders_cnt) OVER (PARTITION BY "category" ORDER BY month_start)
                                            AS prev_orders_cnt,
        LAG(revenue)    OVER (PARTITION BY "category" ORDER BY month_start)
                                            AS prev_revenue
    FROM monthly_stats
),

growth_rates AS (          -- percentage changes month‑to‑month
    SELECT
        "category",
        month_start,
        100.0 * (orders_cnt - prev_orders_cnt) / prev_orders_cnt
                                            AS orders_growth_pct,
        CASE
             WHEN prev_revenue IS NULL OR prev_revenue = 0
                  THEN NULL
             ELSE 100.0 * (revenue - prev_revenue) / prev_revenue
        END                                 AS revenue_growth_pct
    FROM add_prev
    WHERE prev_orders_cnt IS NOT NULL              -- need a prior month
          AND prev_orders_cnt <> 0
),

avg_order_growth AS (      -- average order‑count growth per category
    SELECT
        "category",
        AVG(orders_growth_pct)  AS avg_monthly_orders_growth_pct
    FROM growth_rates
    GROUP BY "category"
),

top_category AS (          -- the single category with highest growth
    SELECT *
    FROM   avg_order_growth
    ORDER BY avg_monthly_orders_growth_pct DESC NULLS LAST
    LIMIT 1
),

final_revenue_growth AS (  -- average revenue growth for that category
    SELECT
        tc."category",
        tc.avg_monthly_orders_growth_pct,
        AVG(gr.revenue_growth_pct)  AS avg_monthly_revenue_growth_pct
    FROM  top_category   tc
    JOIN  growth_rates   gr
          ON gr."category" = tc."category"
    GROUP BY
        tc."category",
        tc.avg_monthly_orders_growth_pct
)

SELECT
    "category",
    ROUND(avg_monthly_orders_growth_pct , 4) AS avg_monthly_orders_growth_pct,
    ROUND(avg_monthly_revenue_growth_pct, 4) AS avg_monthly_revenue_growth_pct
FROM final_revenue_growth;