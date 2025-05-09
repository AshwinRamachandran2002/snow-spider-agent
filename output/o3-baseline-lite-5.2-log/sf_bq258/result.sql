WITH delivered_orders AS (
    SELECT
        p."category"                                             AS category,
        DATE_TRUNC('month', TO_TIMESTAMP(oi."delivered_at"/1e6)) AS month_start,
        oi."sale_price"                                          AS sale_price,
        p."cost"                                                 AS product_cost,
        oi."order_id"                                            AS order_id
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"       o
         ON oi."order_id" = o."order_id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"     p
         ON oi."product_id" = p."id"
    WHERE o."status" = 'Complete'
      AND oi."status" = 'Complete'
      AND oi."delivered_at" IS NOT NULL
      AND TO_TIMESTAMP(oi."delivered_at"/1e6) < '2022-01-01'
), monthly_agg AS (
    SELECT
        category,
        month_start,
        SUM(sale_price)                                           AS total_revenue,
        COUNT(DISTINCT order_id)                                  AS total_orders,
        SUM(product_cost)                                         AS total_cost,
        SUM(sale_price) - SUM(product_cost)                       AS total_profit,
        CASE WHEN SUM(product_cost) = 0 THEN NULL
             ELSE (SUM(sale_price) - SUM(product_cost))/SUM(product_cost)
        END                                                       AS profit_to_cost_ratio
    FROM delivered_orders
    GROUP BY category, month_start
)
SELECT
    category,
    TO_CHAR(month_start, 'YYYY-MM')                                                AS year_month,
    total_revenue,
    total_orders,
    ROUND(
        100 *
        (total_revenue - LAG(total_revenue) OVER (PARTITION BY category ORDER BY month_start))
        / NULLIF(LAG(total_revenue) OVER (PARTITION BY category ORDER BY month_start), 0)
    , 4)                                                                            AS revenue_mom_growth_pct,
    ROUND(
        100 *
        (total_orders - LAG(total_orders) OVER (PARTITION BY category ORDER BY month_start))
        / NULLIF(LAG(total_orders) OVER (PARTITION BY category ORDER BY month_start), 0)
    , 4)                                                                            AS orders_mom_growth_pct,
    total_cost,
    total_profit,
    profit_to_cost_ratio
FROM monthly_agg
ORDER BY category, month_start;