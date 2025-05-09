/* 1)  Work with completed order-items only
   2)  For every month & category count distinct orders
   3)  Turn those counts into month-over-month % changes
   4)  Average the % changes → avg order-growth per category
   5)  Keep the single category with the highest average
   6)  For that category repeat the calculation for revenue
   7)  Return the category together with both averages          */
WITH monthly_orders AS (   -- distinct-order counts per month & category
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP(oi."created_at" / 1000000))      AS order_month,
        p."category"                                                     AS category,
        COUNT(DISTINCT oi."order_id")                                    AS monthly_order_cnt
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS   oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.PRODUCTS      p
         ON oi."product_id" = p."id"
    WHERE oi."status" = 'Complete'
    GROUP BY order_month, category
),
order_growth AS (          -- % change in order count vs previous month
    SELECT
        category,
        order_month,
        ( (monthly_order_cnt
            - LAG(monthly_order_cnt) OVER (PARTITION BY category ORDER BY order_month))
          / NULLIF(LAG(monthly_order_cnt) OVER (PARTITION BY category ORDER BY order_month), 0)
        ) * 100                                                AS pct_order_growth
    FROM monthly_orders
),
avg_order_growth AS (      -- average monthly growth per category
    SELECT
        category,
        AVG(pct_order_growth)                                  AS avg_pct_order_growth
    FROM order_growth
    WHERE pct_order_growth IS NOT NULL
    GROUP BY category
),
top_category AS (          -- keep the single best category
    SELECT category, avg_pct_order_growth
    FROM   avg_order_growth
    ORDER BY avg_pct_order_growth DESC NULLS LAST
    LIMIT 1
),
monthly_revenue AS (       -- month-by-month revenue for the best category
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP(oi."created_at" / 1000000))      AS order_month,
        SUM(oi."sale_price")                                             AS revenue
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS   oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.PRODUCTS      p
         ON oi."product_id" = p."id"
    JOIN top_category tc
         ON p."category" = tc.category
    WHERE oi."status" = 'Complete'
    GROUP BY order_month
),
rev_growth AS (            -- % change in revenue vs previous month
    SELECT
        order_month,
        ( (revenue
            - LAG(revenue) OVER (ORDER BY order_month))
          / NULLIF(LAG(revenue) OVER (ORDER BY order_month), 0)
        ) * 100                                                AS pct_rev_growth
    FROM monthly_revenue
),
avg_rev_growth AS (        -- average monthly revenue growth
    SELECT AVG(pct_rev_growth) AS avg_pct_rev_growth
    FROM   rev_growth
    WHERE  pct_rev_growth IS NOT NULL
)
SELECT
    tc.category                                                AS product_category,
    ROUND(tc.avg_pct_order_growth , 2)                         AS avg_monthly_order_growth_pct,
    ROUND(ar.avg_pct_rev_growth  , 2)                          AS avg_monthly_revenue_growth_pct
FROM top_category   tc
CROSS JOIN avg_rev_growth ar;