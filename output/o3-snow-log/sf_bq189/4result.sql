/*-----------------------------------------------------------
  1)  For every product category, compute the month-over-month
      % growth in DISTINCT order-count and average those
      percentages.

  2)  Pick the category with the highest average growth
      (top_growth_category).

  3)  For that category, calculate the month-over-month
      % growth in total revenue (SUM of sale_price) and
      average those percentages.

  The query returns one row containing:
      • top_growth_category
      • avg_monthly_order_growth_pct
      • avg_monthly_revenue_growth_pct
-----------------------------------------------------------*/
WITH order_counts AS (   -- distinct-order count per category & month
    SELECT
        p."category",
        DATE_TRUNC('month', TO_TIMESTAMP(oi."created_at" / 1000000)) AS order_month,
        COUNT(DISTINCT oi."order_id")                               AS unique_orders
    FROM "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS"  oi
    JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."PRODUCTS"     p
          ON oi."product_id" = p."id"
    WHERE oi."status" = 'Complete'
    GROUP BY p."category", order_month
),
order_growth AS (         -- month-over-month % growth in order count
    SELECT
        oc.*,
        100.0 * (oc.unique_orders
                 - LAG(oc.unique_orders) OVER (PARTITION BY oc."category" ORDER BY oc.order_month))
                 / NULLIF(LAG(oc.unique_orders) OVER (PARTITION BY oc."category" ORDER BY oc.order_month), 0)
                 AS pct_growth_orders
    FROM order_counts oc
),
avg_order_growth AS (     -- average MoM order-growth % per category
    SELECT
        "category",
        AVG(pct_growth_orders) AS avg_monthly_order_growth_pct
    FROM order_growth
    GROUP BY "category"
),
top_category AS (         -- the single category with highest avg growth
    SELECT
        "category",
        avg_monthly_order_growth_pct
    FROM avg_order_growth
    ORDER BY avg_monthly_order_growth_pct DESC NULLS LAST
    LIMIT 1
),
monthly_revenue AS (      -- monthly revenue for that top category
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP(oi."created_at" / 1000000)) AS order_month,
        SUM(oi."sale_price")                                        AS monthly_revenue
    FROM "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS"  oi
    JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."PRODUCTS"     p
          ON oi."product_id" = p."id"
    JOIN top_category tc                                         -- keep only the top category
          ON p."category" = tc."category"
    WHERE oi."status" = 'Complete'
    GROUP BY order_month
),
revenue_growth AS (        -- month-over-month % growth in revenue
    SELECT
        mr.order_month,
        mr.monthly_revenue,
        100.0 * (mr.monthly_revenue
                 - LAG(mr.monthly_revenue) OVER (ORDER BY mr.order_month))
                 / NULLIF(LAG(mr.monthly_revenue) OVER (ORDER BY mr.order_month), 0)
                 AS pct_growth_revenue
    FROM monthly_revenue mr
),
avg_revenue_growth AS (    -- average MoM revenue-growth % for top category
    SELECT AVG(pct_growth_revenue) AS avg_monthly_revenue_growth_pct
    FROM revenue_growth
)

SELECT
    tc."category"                       AS top_growth_category,
    tc.avg_monthly_order_growth_pct,
    arg.avg_monthly_revenue_growth_pct
FROM top_category tc
CROSS JOIN avg_revenue_growth arg;