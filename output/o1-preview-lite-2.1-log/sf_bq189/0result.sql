WITH monthly_order_counts AS (
    SELECT 
        DATE_TRUNC('month', TO_TIMESTAMP(oi."created_at" / 1e6)) AS "order_month",
        p."category",
        COUNT(DISTINCT oi."order_id") AS "order_count"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS" oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS" p
        ON oi."product_id" = p."id"
    WHERE oi."status" = 'Complete'
    GROUP BY "order_month", p."category"
),
order_growth_rates AS (
    SELECT
        "category",
        "order_month",
        "order_count",
        LAG("order_count") OVER (PARTITION BY "category" ORDER BY "order_month") AS "prev_order_count",
        CASE
            WHEN LAG("order_count") OVER (PARTITION BY "category" ORDER BY "order_month") IS NOT NULL
                AND LAG("order_count") OVER (PARTITION BY "category" ORDER BY "order_month") != 0
            THEN
                ROUND((
                    CAST("order_count" AS FLOAT) - LAG("order_count") OVER (PARTITION BY "category" ORDER BY "order_month")
                ) / LAG("order_count") OVER (PARTITION BY "category" ORDER BY "order_month"), 4)
            ELSE NULL
        END AS "order_growth_rate"
    FROM monthly_order_counts
),
avg_order_growth_rate AS (
    SELECT
        "category",
        AVG("order_growth_rate") AS "avg_order_growth_rate"
    FROM order_growth_rates
    WHERE "order_growth_rate" IS NOT NULL
    GROUP BY "category"
),
category_with_max_growth AS (
    SELECT
        "category"
    FROM avg_order_growth_rate
    ORDER BY "avg_order_growth_rate" DESC NULLS LAST
    LIMIT 1
),
monthly_revenues AS (
    SELECT 
        DATE_TRUNC('month', TO_TIMESTAMP(oi."created_at" / 1e6)) AS "order_month",
        SUM(oi."sale_price") AS "monthly_revenue"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS" oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS" p
        ON oi."product_id" = p."id"
    WHERE oi."status" = 'Complete'
        AND p."category" = (SELECT "category" FROM category_with_max_growth)
    GROUP BY "order_month"
),
revenue_growth_rates AS (
    SELECT
        "order_month",
        "monthly_revenue",
        LAG("monthly_revenue") OVER (ORDER BY "order_month") AS "prev_monthly_revenue",
        CASE
            WHEN LAG("monthly_revenue") OVER (ORDER BY "order_month") IS NOT NULL
                AND LAG("monthly_revenue") OVER (ORDER BY "order_month") != 0
            THEN
                ROUND((
                    CAST("monthly_revenue" AS FLOAT) - LAG("monthly_revenue") OVER (ORDER BY "order_month")
                ) / LAG("monthly_revenue") OVER (ORDER BY "order_month"), 4)
            ELSE NULL
        END AS "revenue_growth_rate"
    FROM monthly_revenues
)
SELECT ROUND(AVG("revenue_growth_rate"), 4) AS "Average_Monthly_Revenue_Growth_Rate"
FROM revenue_growth_rates
WHERE "revenue_growth_rate" IS NOT NULL;