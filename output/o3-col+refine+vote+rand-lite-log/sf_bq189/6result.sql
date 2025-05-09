/*--------------------------------------------------------------------
  1) Work out DISTINCT-order counts per month & product category,
     then the month-over-month % change (“pct_order_growth”).
  2) Average those % changes → pick the category with the
     highest average growth (“top_category”).
  3) For that category, repeat the exercise on monthly revenue
     (sum of sale_price) to get its average % revenue growth.
--------------------------------------------------------------------*/
WITH monthly_order_counts AS (                        -- step-1a
    SELECT
        DATE_TRUNC('month',
                   TO_TIMESTAMP(oi."created_at" / 1000000)) AS "order_month",
        p."category"                                      AS "product_category",
        COUNT(DISTINCT oi."order_id")                     AS "distinct_orders"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS  oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.PRODUCTS     p
      ON p."id" = oi."product_id"
    WHERE oi."status" = 'Complete'
    GROUP BY "order_month", "product_category"
),
monthly_order_growth AS (                               -- step-1b
    SELECT
        "product_category",
        "order_month",
        "distinct_orders",
        LAG("distinct_orders") OVER
            (PARTITION BY "product_category" ORDER BY "order_month") AS "prev_orders",
        CASE
            WHEN LAG("distinct_orders") OVER
                   (PARTITION BY "product_category" ORDER BY "order_month") IS NULL
                 OR LAG("distinct_orders") OVER
                   (PARTITION BY "product_category" ORDER BY "order_month") = 0
            THEN NULL
            ELSE ( ("distinct_orders"
                     - LAG("distinct_orders") OVER
                         (PARTITION BY "product_category" ORDER BY "order_month"))
                   / LAG("distinct_orders") OVER
                         (PARTITION BY "product_category" ORDER BY "order_month") ) * 100
        END                                              AS "pct_order_growth"
    FROM monthly_order_counts
),
avg_order_growth AS (                                   -- step-1c
    SELECT
        "product_category",
        AVG("pct_order_growth") AS "avg_monthly_order_growth_pct"
    FROM monthly_order_growth
    GROUP BY "product_category"
),
top_category AS (                                       -- step-2
    SELECT
        "product_category",
        "avg_monthly_order_growth_pct"
    FROM avg_order_growth
    ORDER BY "avg_monthly_order_growth_pct" DESC NULLS LAST
    LIMIT 1
),
monthly_revenue AS (                                    -- step-3a
    SELECT
        DATE_TRUNC('month',
                   TO_TIMESTAMP(oi."created_at" / 1000000))      AS "order_month",
        SUM(oi."sale_price")                                    AS "monthly_revenue"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS  oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.PRODUCTS     p
      ON p."id" = oi."product_id"
    JOIN top_category tc                                   -- only the winning category
      ON tc."product_category" = p."category"
    WHERE oi."status" = 'Complete'
    GROUP BY "order_month"
),
monthly_revenue_growth AS (                               -- step-3b
    SELECT
        "order_month",
        "monthly_revenue",
        LAG("monthly_revenue") OVER (ORDER BY "order_month") AS "prev_revenue",
        CASE
            WHEN LAG("monthly_revenue") OVER (ORDER BY "order_month") IS NULL
                 OR LAG("monthly_revenue") OVER (ORDER BY "order_month") = 0
            THEN NULL
            ELSE ( ("monthly_revenue"
                     - LAG("monthly_revenue") OVER (ORDER BY "order_month"))
                   / LAG("monthly_revenue") OVER (ORDER BY "order_month") ) * 100
        END                                               AS "pct_revenue_growth"
    FROM monthly_revenue
),
avg_revenue_growth AS (                                  -- step-3c
    SELECT
        AVG("pct_revenue_growth") AS "avg_monthly_revenue_growth_pct"
    FROM monthly_revenue_growth
)

SELECT
    tc."product_category",
    ROUND(tc."avg_monthly_order_growth_pct", 4)   AS "avg_monthly_order_growth_pct",
    ROUND(arg."avg_monthly_revenue_growth_pct",4) AS "avg_monthly_revenue_growth_pct"
FROM top_category      tc
CROSS JOIN avg_revenue_growth arg;