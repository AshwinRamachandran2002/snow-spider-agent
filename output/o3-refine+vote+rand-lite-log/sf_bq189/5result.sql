WITH completed_orders AS (         -- only orders that reached the “Complete” state
    SELECT  "order_id",
            "created_at"
    FROM    THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS
    WHERE   "status" = 'Complete'
),

order_details AS (                 -- line‑items belonging to those completed orders
    SELECT  oi."order_id",
            TO_TIMESTAMP_LTZ(co."created_at" / 1000000)     AS order_ts,
            p."category"                                    AS product_category,
            oi."sale_price"
    FROM    THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS  oi
    JOIN    completed_orders                                 co  ON co."order_id" = oi."order_id"
    JOIN    THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.PRODUCTS     p   ON p."id"        = oi."product_id"
),

monthly_stats AS (                 -- orders & revenue per category / month
    SELECT  product_category,
            DATE_TRUNC('month', order_ts)   AS order_month,
            COUNT(DISTINCT "order_id")      AS unique_orders,
            SUM("sale_price")               AS revenue
    FROM    order_details
    GROUP BY product_category, order_month
),

monthly_growth AS (                -- current vs. previous month
    SELECT  product_category,
            order_month,
            unique_orders,
            revenue,
            LAG(unique_orders) OVER (PARTITION BY product_category ORDER BY order_month) AS prev_orders,
            LAG(revenue)       OVER (PARTITION BY product_category ORDER BY order_month) AS prev_revenue
    FROM    monthly_stats
),

growth_rates AS (                  -- % growth for orders and revenue
    SELECT  product_category,
            order_month,
            CASE WHEN prev_orders  > 0 THEN (unique_orders - prev_orders ) * 100.0 / prev_orders  END AS order_growth_pct,
            CASE WHEN prev_revenue > 0 THEN (revenue      - prev_revenue) * 100.0 / prev_revenue END AS revenue_growth_pct
    FROM    monthly_growth
),

avg_order_growth AS (              -- average monthly order growth per category
    SELECT  product_category,
            AVG(order_growth_pct) AS avg_order_growth_pct
    FROM    growth_rates
    WHERE   order_growth_pct IS NOT NULL
    GROUP BY product_category
),

top_category AS (                  -- category with the highest avg order growth
    SELECT  product_category,
            avg_order_growth_pct
    FROM    avg_order_growth
    ORDER BY avg_order_growth_pct DESC NULLS LAST
    LIMIT 1
),

revenue_growth_of_top AS (         -- avg monthly revenue growth for that category
    SELECT  gr.product_category,
            AVG(gr.revenue_growth_pct) AS avg_revenue_growth_pct
    FROM    growth_rates gr
    JOIN    top_category  tc
            ON tc.product_category = gr.product_category
    WHERE   gr.revenue_growth_pct IS NOT NULL
    GROUP BY gr.product_category
)

SELECT  tc.product_category,
        ROUND(tc.avg_order_growth_pct,   4) AS avg_monthly_order_growth_pct,
        ROUND(rg.avg_revenue_growth_pct, 4) AS avg_monthly_revenue_growth_pct
FROM    top_category             tc
JOIN    revenue_growth_of_top    rg
        ON rg.product_category = tc.product_category;