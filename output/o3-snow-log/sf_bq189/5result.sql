/*--------------------------------------------------------------
  1)  Count monthly DISTINCT orders per product category
  2)  Compute MoM % growth in orders, then average per category
  3)  Identify the category with the highest average MoM order-growth
  4)  For that winning category, calculate the average MoM revenue-growth
----------------------------------------------------------------*/
WITH monthly_orders AS (          -- step-1
    SELECT
        p."category"                                                   AS category ,
        DATE_TRUNC('month', TO_TIMESTAMP_NTZ(oi."created_at"/1e6))     AS month_start ,
        COUNT(DISTINCT oi."order_id")                                  AS orders_cnt
    FROM  THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  oi
    JOIN  THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"      p
          ON p."id" = oi."product_id"
    WHERE oi."status" = 'Complete'
    GROUP BY 1,2
),
order_growth AS (                 -- step-2
    SELECT
        category ,
        month_start ,
        orders_cnt ,
        (orders_cnt
         -  LAG(orders_cnt) OVER (PARTITION BY category ORDER BY month_start))
        / NULLIF(LAG(orders_cnt)  OVER (PARTITION BY category ORDER BY month_start),0)
          AS pct_growth_orders
    FROM monthly_orders
),
avg_order_growth AS (             -- step-3
    SELECT
        category ,
        AVG(pct_growth_orders) AS avg_mom_order_growth
    FROM order_growth
    GROUP BY category
),
top_category AS (                 -- highest-growth category
    SELECT category , avg_mom_order_growth
    FROM   avg_order_growth
    QUALIFY RANK() OVER (ORDER BY avg_mom_order_growth DESC NULLS LAST) = 1
),
monthly_revenue AS (              -- revenue series for the winner
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP_NTZ(oi."created_at"/1e6)) AS month_start ,
        SUM(oi."sale_price")                                       AS revenue
    FROM  THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  oi
    JOIN  THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"      p
          ON p."id" = oi."product_id"
    JOIN  top_category tc
          ON tc.category = p."category"
    WHERE oi."status" = 'Complete'
    GROUP BY 1
),
revenue_growth AS (               -- MoM % growth in revenue
    SELECT
        month_start ,
        revenue ,
        (revenue
         -  LAG(revenue) OVER (ORDER BY month_start))
        / NULLIF(LAG(revenue)  OVER (ORDER BY month_start),0)
          AS pct_growth_revenue
    FROM monthly_revenue
),
avg_revenue_growth AS (           -- step-4
    SELECT AVG(pct_growth_revenue) AS avg_mom_revenue_growth
    FROM   revenue_growth
)
-- Final result: winning category plus both averaged growth metrics
SELECT
    tc.category ,
    tc.avg_mom_order_growth ,
    arg.avg_mom_revenue_growth
FROM   top_category tc
CROSS  JOIN avg_revenue_growth arg;