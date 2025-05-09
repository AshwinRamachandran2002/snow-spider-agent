WITH completed_items AS (          -- 1) all completed order items with their product category
    SELECT 
        oi."order_id",
        oi."sale_price",
        p."category",
        DATE_TRUNC(
            'month',
            TO_TIMESTAMP(oi."created_at" / 1e6)      -- convert micro‑seconds to timestamp, keep month bucket
        )     AS month_start
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"   oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"      p
          ON oi."product_id" = p."id"
    WHERE oi."status" = 'Complete'
),

monthly_metrics AS (               -- 2) monthly order count & revenue per category
    SELECT
        "category",
        month_start,
        COUNT(DISTINCT "order_id")           AS orders_cnt,
        SUM("sale_price")                    AS revenue
    FROM completed_items
    GROUP BY "category", month_start
),

monthly_growth AS (                -- 3) month‑over‑month % growth of orders & revenue
    SELECT
        "category",
        month_start,
        orders_cnt,
        revenue,
        LAG(orders_cnt)  OVER (PARTITION BY "category" ORDER BY month_start) AS prev_orders_cnt,
        LAG(revenue)     OVER (PARTITION BY "category" ORDER BY month_start) AS prev_revenue
    FROM monthly_metrics
),

growth_rates AS (                  -- 4) compute growth percentages, skip months with zero / NULL previous values
    SELECT
        "category",
        month_start,
        CASE 
            WHEN prev_orders_cnt > 0 THEN 
                (orders_cnt - prev_orders_cnt) * 100.0 / prev_orders_cnt
        END  AS orders_growth_pct,
        CASE 
            WHEN prev_revenue > 0 THEN 
                (revenue - prev_revenue) * 100.0 / prev_revenue
        END  AS revenue_growth_pct
    FROM monthly_growth
),

avg_order_growth AS (              -- 5) average monthly order growth per category
    SELECT
        "category",
        AVG(orders_growth_pct) AS avg_orders_growth_pct
    FROM growth_rates
    GROUP BY "category"
),

top_category AS (                  -- 6) pick the category with highest average order growth
    SELECT "category", avg_orders_growth_pct
    FROM   avg_order_growth
    QUALIFY ROW_NUMBER() OVER (ORDER BY avg_orders_growth_pct DESC NULLS LAST) = 1
)

-- 7) Final result: show top category with both average order‑growth and revenue‑growth
SELECT
    tc."category"                                           AS top_category,
    ROUND(tc.avg_orders_growth_pct,   4)                    AS avg_monthly_order_growth_pct,
    ROUND( AVG(gr.revenue_growth_pct), 4)                   AS avg_monthly_revenue_growth_pct
FROM        top_category          tc
JOIN        growth_rates          gr
        ON  tc."category" = gr."category"
GROUP BY    tc."category", tc.avg_orders_growth_pct;