WITH completed_items AS (   -- completed orders delivered before 2022
    SELECT
        oi."order_id"               AS order_id,
        oi."sale_price"             AS sale_price,
        oi."delivered_at"           AS delivered_at,      -- keep un‑quoted alias
        p."category"                AS category,
        p."cost"                    AS product_cost
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS   oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS        o
          ON  o."order_id" = oi."order_id"
         AND o."status"   = 'Complete'
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.PRODUCTS      p
          ON  p."id"      = oi."product_id"
    WHERE oi."status"        = 'Complete'
      AND oi."delivered_at"  IS NOT NULL
      AND TO_TIMESTAMP_NTZ(oi."delivered_at" / 1000000) < DATE '2022-01-01'
),

monthly AS (   -- base monthly aggregates
    SELECT
        category,
        DATE_TRUNC('month', TO_TIMESTAMP_NTZ(delivered_at / 1000000))       AS month_start,
        SUM(sale_price)                                                     AS total_revenue,
        COUNT(DISTINCT order_id)                                            AS total_orders,
        SUM(product_cost)                                                   AS total_cost,
        SUM(sale_price) - SUM(product_cost)                                 AS total_profit
    FROM completed_items
    GROUP BY category,
             DATE_TRUNC('month', TO_TIMESTAMP_NTZ(delivered_at / 1000000))
),

monthly_with_growth AS (   -- add month‑over‑month growth
    SELECT
        category,
        month_start,
        total_revenue,
        total_orders,
        total_cost,
        total_profit,
        LAG(total_revenue) OVER (PARTITION BY category ORDER BY month_start) AS prev_revenue,
        LAG(total_orders)  OVER (PARTITION BY category ORDER BY month_start) AS prev_orders
    FROM monthly
)

SELECT
    category,
    TO_CHAR(month_start, 'YYYY-MM')                                         AS year_month,
    total_revenue,
    total_orders,
    ROUND( (total_revenue - prev_revenue) / NULLIF(prev_revenue,0) * 100, 4) AS revenue_mom_pct,
    ROUND( (total_orders  - prev_orders ) / NULLIF(prev_orders ,0) * 100, 4) AS orders_mom_pct,
    total_cost,
    total_profit,
    ROUND(total_profit / NULLIF(total_cost,0), 4)                           AS profit_to_cost_ratio
FROM monthly_with_growth
ORDER BY category, month_start;