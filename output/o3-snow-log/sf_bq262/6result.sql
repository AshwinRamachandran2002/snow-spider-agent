WITH monthly_category_sales AS (
    /* 1. Aggregate orders by month (month start date) and product category */
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP_LTZ("created_at"/1000000))     AS month_start,
        TO_CHAR(DATE_TRUNC('month', TO_TIMESTAMP_LTZ("created_at"/1000000)), 'YYYY-MM') AS month,
        p."category"                                                   AS product_category,
        COUNT(DISTINCT oi."order_id")                                  AS total_orders,
        SUM(oi."sale_price")                                           AS total_revenue,
        SUM(p."cost")                                                  AS total_cost,
        SUM(oi."sale_price" - p."cost")                                AS total_profit
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS   oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.PRODUCTS      p
          ON oi."product_id" = p."id"
    /* June-December 2019 (inclusive) so June is available for MoM baseline */
    WHERE DATE_TRUNC('month', TO_TIMESTAMP_LTZ(oi."created_at"/1000000))
          BETWEEN '2019-06-01' AND '2019-12-01'
    GROUP BY
        month_start,
        product_category
), monthly_with_growth AS (
    /* 2. Calculate month-over-month growth rates by category */
    SELECT
        month,
        product_category,
        total_orders,
        total_revenue,
        total_profit,
        /* MoM growth vs previous month (June is the baseline for July) */
        ROUND(
            (total_orders - LAG(total_orders) OVER (PARTITION BY product_category ORDER BY month_start))
            / NULLIF(LAG(total_orders) OVER (PARTITION BY product_category ORDER BY month_start), 0),
            4
        ) AS orders_mom_growth,
        ROUND(
            (total_revenue - LAG(total_revenue) OVER (PARTITION BY product_category ORDER BY month_start))
            / NULLIF(LAG(total_revenue) OVER (PARTITION BY product_category ORDER BY month_start), 0),
            4
        ) AS revenue_mom_growth,
        ROUND(
            (total_profit - LAG(total_profit) OVER (PARTITION BY product_category ORDER BY month_start))
            / NULLIF(LAG(total_profit) OVER (PARTITION BY product_category ORDER BY month_start), 0),
            4
        ) AS profit_mom_growth
    FROM monthly_category_sales
)
SELECT
    month,
    product_category,
    total_orders,
    total_revenue,
    total_profit,
    orders_mom_growth,
    revenue_mom_growth,
    profit_mom_growth
FROM monthly_with_growth
/* 3. Exclude June from final output but keep it for growth calculations */
WHERE month >= '2019-07'
ORDER BY
    month,
    product_category;