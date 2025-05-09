WITH delivered_orders AS (         -- 1. pull all completed & delivered-before-2022 order-items
    SELECT 
        oi."order_id",
        oi."product_id",
        oi."sale_price",
        oi."delivered_at",
        p."category"                 AS product_category,
        p."cost"                     AS product_unit_cost
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"     p
          ON oi."product_id" = p."id"
    WHERE oi."status" = 'Complete'
      AND oi."delivered_at" IS NOT NULL
      AND TO_TIMESTAMP(oi."delivered_at"/1000000) < '2022-01-01'         -- before 2022-01-01
), 

monthly_agg AS (                    -- 2. aggregate by delivery year / month & category
    SELECT
        YEAR(TO_TIMESTAMP("delivered_at"/1000000))   AS delivery_year,
        MONTH(TO_TIMESTAMP("delivered_at"/1000000))  AS delivery_month,
        product_category,
        SUM("sale_price")            AS total_revenue,
        COUNT(DISTINCT "order_id")   AS total_completed_orders,
        SUM(product_unit_cost)       AS total_cost
    FROM delivered_orders
    GROUP BY delivery_year,
             delivery_month,
             product_category
), 

monthly_profit AS (                 -- 3. add profit & profit-to-cost ratio
    SELECT
        *,
        total_revenue - total_cost                       AS total_profit,
        CASE WHEN total_cost <> 0 
             THEN ROUND(total_profit/total_cost,4)
             ELSE NULL 
        END                                              AS profit_to_cost_ratio
    FROM monthly_agg
), 

final AS (                          -- 4. calculate MoM % growth with window functions
    SELECT
        delivery_year,
        delivery_month,
        product_category,
        ROUND(total_revenue,4)                           AS total_revenue,
        total_completed_orders,
        ROUND(
              100 * (
                 total_revenue  
                 - LAG(total_revenue) OVER (PARTITION BY product_category 
                                             ORDER BY delivery_year, delivery_month)
              )
            / NULLIF(
                 LAG(total_revenue) OVER (PARTITION BY product_category 
                                           ORDER BY delivery_year, delivery_month),
                 0
              ),4)                                       AS revenue_mom_growth_pct,
        ROUND(
              100 * (
                 total_completed_orders  
                 - LAG(total_completed_orders) OVER (PARTITION BY product_category 
                                                      ORDER BY delivery_year, delivery_month)
              )
            / NULLIF(
                 LAG(total_completed_orders) OVER (PARTITION BY product_category 
                                                    ORDER BY delivery_year, delivery_month),
                 0
              ),4)                                       AS orders_mom_growth_pct,
        ROUND(total_cost,4)                              AS total_cost,
        ROUND(total_profit,4)                            AS total_profit,
        profit_to_cost_ratio
    FROM monthly_profit
)

SELECT *
FROM final
ORDER BY product_category, delivery_year, delivery_month;