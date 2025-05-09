WITH order_item_details AS (
    /*--------------------------------------------------------------------
      Bring each order line together with its product cost & category
      and convert micro-seconds since epoch to a timestamp.
    --------------------------------------------------------------------*/
    SELECT
        oi."order_id"                              AS order_id,
        p."category"                               AS product_category,
        oi."sale_price"                            AS sale_price,
        p."cost"                                   AS cost,
        TO_TIMESTAMP_NTZ(oi."created_at" / 1000000) AS created_ts
    FROM "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS"   oi
    JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."PRODUCTS"      p
      ON oi."product_id" = p."id"
),
monthly_metrics AS (
    /*--------------------------------------------------------------------
      Aggregate by month & product category (June-Dec 2019).
    --------------------------------------------------------------------*/
    SELECT
        DATE_TRUNC('month', created_ts)            AS month_start,
        product_category,
        COUNT(DISTINCT order_id)                   AS total_orders,
        SUM(sale_price)                            AS total_revenue,
        SUM(sale_price - cost)                     AS total_profit
    FROM order_item_details
    WHERE created_ts >= '2019-06-01'::DATE
      AND created_ts <  '2020-01-01'::DATE
    GROUP BY month_start, product_category
),
growth_calc AS (
    /*--------------------------------------------------------------------
      Compute MoM growth, with June 2019 as the baseline.
    --------------------------------------------------------------------*/
    SELECT
        month_start,
        TO_CHAR(month_start, 'YYYY-MM')            AS month,
        product_category,
        total_orders,
        total_revenue,
        total_profit,
        LAG(total_orders)  OVER (PARTITION BY product_category ORDER BY month_start) AS prev_orders,
        LAG(total_revenue) OVER (PARTITION BY product_category ORDER BY month_start) AS prev_revenue,
        LAG(total_profit)  OVER (PARTITION BY product_category ORDER BY month_start) AS prev_profit
    FROM monthly_metrics
)
SELECT
    month,
    product_category,
    total_orders,
    total_revenue,
    total_profit,
    ROUND((total_orders  - prev_orders)  / NULLIF(prev_orders,  0), 4) AS orders_mom_growth,
    ROUND((total_revenue - prev_revenue) / NULLIF(prev_revenue, 0), 4) AS revenue_mom_growth,
    ROUND((total_profit  - prev_profit)  / NULLIF(prev_profit,  0), 4) AS profit_mom_growth
FROM growth_calc
WHERE month <> '2019-06'             -- exclude June from final display
ORDER BY month_start ASC, product_category;