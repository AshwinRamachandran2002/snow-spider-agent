WITH monthly_stats AS (
    /* 1.  Aggregate June-2019 → Dec-2019 numbers by month & product category                */
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP_NTZ(oi."created_at" / 1000000))   AS month_start,
        ii."product_category"                                              AS product_category,
        COUNT(DISTINCT oi."order_id")                                      AS total_orders,
        SUM(oi."sale_price")                                               AS total_revenue,
        SUM(oi."sale_price" - ii."cost")                                   AS total_profit
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS       oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.INVENTORY_ITEMS   ii
         ON oi."inventory_item_id" = ii."id"
    WHERE oi."created_at" >= 1559347200000000          -- 2019-06-01 00:00:00
      AND oi."created_at" <  1577836800000000          -- 2020-01-01 00:00:00
    GROUP BY month_start, ii."product_category"
), growth AS (
    /* 2.  Calculate MoM growth, using the previous month (June is baseline for July)       */
    SELECT
        month_start,
        product_category,
        total_orders,
        total_revenue,
        total_profit,
        ROUND(
            100 * (total_orders - LAG(total_orders) OVER (PARTITION BY product_category ORDER BY month_start))
                 / NULLIF(LAG(total_orders) OVER (PARTITION BY product_category ORDER BY month_start), 0)
        , 4)                                                               AS orders_mom_growth_pct,
        ROUND(
            100 * (total_revenue - LAG(total_revenue) OVER (PARTITION BY product_category ORDER BY month_start))
                 / NULLIF(LAG(total_revenue) OVER (PARTITION BY product_category ORDER BY month_start), 0)
        , 4)                                                               AS revenue_mom_growth_pct,
        ROUND(
            100 * (total_profit - LAG(total_profit) OVER (PARTITION BY product_category ORDER BY month_start))
                 / NULLIF(LAG(total_profit) OVER (PARTITION BY product_category ORDER BY month_start), 0)
        , 4)                                                               AS profit_mom_growth_pct
    FROM monthly_stats
)
SELECT
    TO_CHAR(month_start, 'YYYY-MM')            AS "month",
    product_category,
    total_orders,
    total_revenue,
    total_profit,
    orders_mom_growth_pct,
    revenue_mom_growth_pct,
    profit_mom_growth_pct
FROM growth
/* 3.  Exclude June 2019 from final output while keeping it for growth calculations         */
WHERE month_start >= '2019-07-01'  AND month_start < '2020-01-01'
ORDER BY month_start, product_category;