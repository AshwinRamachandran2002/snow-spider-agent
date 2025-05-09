WITH base AS (   -- every completed, delivered-before-2022 order-item
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP("oi"."delivered_at" / 1000000))           AS month_start ,
        "p"."category"                                                             AS category ,
        "oi"."order_id"                                                            AS order_id ,
        "oi"."sale_price"                                                          AS sale_price ,
        "p"."cost"                                                                 AS product_cost
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS         AS "oi"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS              AS "o"
          ON "oi"."order_id" = "o"."order_id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.PRODUCTS            AS "p"
          ON "oi"."product_id" = "p"."id"
    WHERE "o"."status" = 'Complete'                                          -- only completed orders
      AND "oi"."delivered_at" IS NOT NULL
      AND TO_TIMESTAMP("oi"."delivered_at" / 1000000) < '2022-01-01'         -- delivered before 2022
),

monthly AS (     -- aggregate to month & category
    SELECT
        month_start ,
        category ,
        SUM(sale_price)                          AS total_revenue ,
        COUNT(DISTINCT order_id)                 AS total_orders ,
        SUM(product_cost)                        AS total_cost
    FROM base
    GROUP BY month_start , category
),

profit_calc AS (  -- profit & ratio
    SELECT
        category ,
        month_start ,
        total_revenue ,
        total_orders ,
        total_cost ,
        (total_revenue - total_cost)                                 AS total_profit ,
        CASE WHEN total_cost <> 0
             THEN (total_revenue - total_cost) / total_cost
        END                                                         AS profit_to_cost_ratio
    FROM monthly
)

SELECT
    category ,
    TO_CHAR(month_start , 'YYYY-MM')                                             AS year_month ,
    total_revenue ,
    total_orders ,
    ROUND( 100 * ( total_revenue
                   - LAG(total_revenue) OVER (PARTITION BY category ORDER BY month_start)
                 ) / NULLIF(LAG(total_revenue) OVER (PARTITION BY category ORDER BY month_start) , 0)
         , 4)                                                                    AS revenue_mom_growth_pct ,
    ROUND( 100 * ( total_orders
                   - LAG(total_orders) OVER (PARTITION BY category ORDER BY month_start)
                 ) / NULLIF(LAG(total_orders) OVER (PARTITION BY category ORDER BY month_start) , 0)
         , 4)                                                                    AS orders_mom_growth_pct ,
    total_cost ,
    total_profit ,
    ROUND(profit_to_cost_ratio , 4)                                              AS profit_to_cost_ratio
FROM profit_calc
ORDER BY category , month_start NULLS LAST;