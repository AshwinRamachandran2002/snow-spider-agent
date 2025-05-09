WITH completed_deliveries AS (   -- 1. delivered, complete order‑items before 2022
    SELECT
        p."category"                                           AS product_category,
        DATE_TRUNC(
            'month',
            TO_TIMESTAMP_LTZ(o."delivered_at"::NUMBER / 1000000)
        )                                                      AS delivered_month,
        oi."sale_price"                                        AS sale_price,
        p."cost"                                               AS product_cost,
        oi."order_id"                                          AS order_id
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS   oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS        o  ON o."order_id" = oi."order_id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.PRODUCTS      p  ON p."id"       = oi."product_id"
    WHERE o."status" = 'Complete'
      AND o."delivered_at" IS NOT NULL
      AND TO_TIMESTAMP_LTZ(o."delivered_at"::NUMBER / 1000000) < '2022-01-01'
),
monthly AS (   -- 2. monthly aggregation
    SELECT
        product_category,
        delivered_month,
        SUM(sale_price)                                  AS total_revenue,
        COUNT(DISTINCT order_id)                         AS total_completed_orders,
        SUM(product_cost)                                AS total_cost,
        SUM(sale_price) - SUM(product_cost)              AS total_profit,
        ROUND(
            (SUM(sale_price) - SUM(product_cost)) / NULLIF(SUM(product_cost), 0),
            4
        )                                                AS profit_to_cost_ratio
    FROM completed_deliveries
    GROUP BY product_category, delivered_month
)
SELECT   -- 3. add MoM growth
    product_category,
    delivered_month,
    total_revenue,
    total_completed_orders,
    ROUND(
        (total_revenue
         - LAG(total_revenue) OVER (PARTITION BY product_category ORDER BY delivered_month))
        / NULLIF(LAG(total_revenue) OVER (PARTITION BY product_category ORDER BY delivered_month), 0)
        * 100,
        4
    )                                                    AS revenue_mom_pct_growth,
    ROUND(
        (total_completed_orders
         - LAG(total_completed_orders) OVER (PARTITION BY product_category ORDER BY delivered_month))
        / NULLIF(LAG(total_completed_orders) OVER (PARTITION BY product_category ORDER BY delivered_month), 0)
        * 100,
        4
    )                                                    AS orders_mom_pct_growth,
    total_cost,
    total_profit,
    profit_to_cost_ratio
FROM monthly
ORDER BY product_category, delivered_month;