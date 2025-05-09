WITH monthly_metrics AS (   /* 1. aggregate monthly figures (June–Dec 2019) */
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP(oi."created_at" / 1000000))                                          AS month_start ,
        TO_CHAR(DATE_TRUNC('month', TO_TIMESTAMP(oi."created_at" / 1000000)), 'YYYY-MM')                     AS month ,
        p."category"                                                                                         AS product_category ,
        COUNT(*)                                                                                             AS total_orders ,
        SUM(oi."sale_price")                                                                                 AS total_revenue ,
        SUM(inv."cost")                                                                                      AS total_cost ,
        SUM(oi."sale_price" - inv."cost")                                                                    AS total_profit
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS      oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.PRODUCTS         p
         ON oi."product_id" = p."id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.INVENTORY_ITEMS  inv
         ON oi."inventory_item_id" = inv."id"
    WHERE DATE_TRUNC('month', TO_TIMESTAMP(oi."created_at" / 1000000))
              BETWEEN '2019-06-01' AND '2019-12-31'
    GROUP BY month_start , month , product_category
),

metrics_with_growth AS (   /* 2. calculate MoM growth using June as base */
    SELECT
        month ,
        product_category ,
        total_orders ,
        total_revenue ,
        total_profit ,
        ROUND(
              (total_orders  - LAG(total_orders)   OVER (PARTITION BY product_category ORDER BY month_start))
              / NULLIF(LAG(total_orders)   OVER (PARTITION BY product_category ORDER BY month_start), 0)
              , 4)                                                                  AS orders_mom_growth ,
        ROUND(
              (total_revenue - LAG(total_revenue)  OVER (PARTITION BY product_category ORDER BY month_start))
              / NULLIF(LAG(total_revenue)  OVER (PARTITION BY product_category ORDER BY month_start), 0)
              , 4)                                                                  AS revenue_mom_growth ,
        ROUND(
              (total_profit  - LAG(total_profit)   OVER (PARTITION BY product_category ORDER BY month_start))
              / NULLIF(LAG(total_profit)   OVER (PARTITION BY product_category ORDER BY month_start), 0)
              , 4)                                                                  AS profit_mom_growth ,
        month_start
    FROM monthly_metrics
)

SELECT
    month ,
    product_category ,
    total_orders ,
    total_revenue ,
    total_profit ,
    orders_mom_growth ,
    revenue_mom_growth ,
    profit_mom_growth
FROM metrics_with_growth
WHERE month >= '2019-07'                 -- omit June but leverage it for growth calculations
ORDER BY month , product_category;