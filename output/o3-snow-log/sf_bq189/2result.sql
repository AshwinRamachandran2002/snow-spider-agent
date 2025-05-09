WITH completed_orders AS (               -- all completed order-items with their month & category
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP(oi."created_at" / 1000000))  AS "order_month",
        p."category"                                                 AS "category",
        oi."order_id"                                                AS "order_id",
        oi."sale_price"                                              AS "sale_price"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS  oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.PRODUCTS     p
          ON p."id" = oi."product_id"
    WHERE oi."status" = 'Complete'
),                                                                   -- monthly distinct-order counts
monthly_counts AS (
    SELECT
        "category",
        "order_month",
        COUNT(DISTINCT "order_id")                                   AS "unique_orders"
    FROM completed_orders
    GROUP BY "category", "order_month"
),                                                                   -- month-to-month % order growth
monthly_order_growth AS (
    SELECT
        "category",
        "order_month",
        "unique_orders",
        LAG("unique_orders") OVER (PARTITION BY "category" ORDER BY "order_month") AS "prev_orders",
        CASE WHEN LAG("unique_orders") OVER (PARTITION BY "category" ORDER BY "order_month") > 0 THEN
                 ("unique_orders" - LAG("unique_orders") OVER (PARTITION BY "category" ORDER BY "order_month"))
                 * 100.0
                 / LAG("unique_orders") OVER (PARTITION BY "category" ORDER BY "order_month")
        END                                                        AS "pct_growth_orders"
    FROM monthly_counts
),                                                                   -- average % growth per category
avg_order_growth AS (
    SELECT
        "category",
        AVG("pct_growth_orders") AS "avg_monthly_order_growth_pct"
    FROM monthly_order_growth
    GROUP BY "category"
),                                                                   -- pick highest-growth category
top_category AS (
    SELECT
        "category",
        "avg_monthly_order_growth_pct"
    FROM avg_order_growth
    QUALIFY ROW_NUMBER() OVER (ORDER BY "avg_monthly_order_growth_pct" DESC NULLS LAST) = 1
),                                                                   -- monthly revenue for that category
monthly_revenue AS (
    SELECT
        "order_month",
        SUM("sale_price") AS "revenue"
    FROM completed_orders
    WHERE "category" = (SELECT "category" FROM top_category)
    GROUP BY "order_month"
),                                                                   -- month-to-month % revenue growth
monthly_revenue_growth AS (
    SELECT
        "order_month",
        "revenue",
        LAG("revenue") OVER (ORDER BY "order_month") AS "prev_revenue",
        CASE WHEN LAG("revenue") OVER (ORDER BY "order_month") > 0 THEN
                 ("revenue" - LAG("revenue") OVER (ORDER BY "order_month")) * 100.0
                 / LAG("revenue") OVER (ORDER BY "order_month")
        END AS "pct_growth_revenue"
    FROM monthly_revenue
),                                                                   -- average % revenue growth
avg_revenue_growth AS (
    SELECT
        AVG("pct_growth_revenue") AS "avg_monthly_revenue_growth_pct"
    FROM monthly_revenue_growth
)
SELECT
    tc."category",
    tc."avg_monthly_order_growth_pct",
    arg."avg_monthly_revenue_growth_pct"
FROM top_category      tc
CROSS JOIN avg_revenue_growth arg;