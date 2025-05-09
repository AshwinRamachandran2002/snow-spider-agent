WITH filtered_items AS (
    SELECT
        oi."order_id",
        oi."product_id",
        oi."sale_price",
        oi."delivered_at"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS" oi
    WHERE oi."status" = 'Complete'
      AND oi."delivered_at" IS NOT NULL
      AND oi."delivered_at" < 1640995200000000
),
item_with_product AS (
    SELECT
        p."category",
        TO_TIMESTAMP_NTZ(fi."delivered_at" / 1000000) AS delivered_ts,
        fi."order_id",
        fi."sale_price",
        p."cost"
    FROM filtered_items fi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS" p
      ON p."id" = fi."product_id"
),
monthly_agg AS (
    SELECT
        "category",
        DATE_TRUNC('month', delivered_ts) AS month_start,
        SUM("sale_price") AS total_revenue,
        COUNT(DISTINCT "order_id") AS total_orders,
        SUM("cost") AS total_cost
    FROM item_with_product
    GROUP BY "category", DATE_TRUNC('month', delivered_ts)
),
calc AS (
    SELECT
        "category",
        EXTRACT(year  FROM month_start) AS year,
        EXTRACT(month FROM month_start) AS month,
        total_revenue,
        total_orders,
        ROUND(
            CASE
                WHEN LAG(total_revenue) OVER (PARTITION BY "category" ORDER BY month_start) IN (0, NULL)
                THEN NULL
                ELSE (total_revenue
                     - LAG(total_revenue) OVER (PARTITION BY "category" ORDER BY month_start))
                     / LAG(total_revenue) OVER (PARTITION BY "category" ORDER BY month_start)
                     * 100
            END, 4) AS revenue_mom_growth_pct,
        ROUND(
            CASE
                WHEN LAG(total_orders) OVER (PARTITION BY "category" ORDER BY month_start) IN (0, NULL)
                THEN NULL
                ELSE (total_orders
                     - LAG(total_orders) OVER (PARTITION BY "category" ORDER BY month_start))
                     / LAG(total_orders) OVER (PARTITION BY "category" ORDER BY month_start)
                     * 100
            END, 4) AS orders_mom_growth_pct,
        total_cost,
        (total_revenue - total_cost) AS total_profit,
        ROUND(
            CASE WHEN total_cost = 0
                 THEN NULL
                 ELSE (total_revenue - total_cost) / total_cost
            END, 4) AS profit_to_cost_ratio
    FROM monthly_agg
)
SELECT
    "category" AS category,
    year,
    month,
    ROUND(total_revenue, 4) AS total_revenue,
    total_orders,
    revenue_mom_growth_pct,
    orders_mom_growth_pct,
    ROUND(total_cost, 4) AS total_cost,
    ROUND(total_profit, 4) AS total_profit,
    profit_to_cost_ratio
FROM calc
ORDER BY "category", year, month;