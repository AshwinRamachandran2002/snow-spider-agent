WITH order_items_2019 AS (
    SELECT 
        oi."order_id",
        oi."sale_price",
        p."cost",
        p."category",
        TO_DATE(TO_TIMESTAMP_NTZ(oi."created_at" / 1000000))               AS order_date
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"   oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"      p
          ON oi."product_id" = p."id"
    WHERE TO_DATE(TO_TIMESTAMP_NTZ(oi."created_at" / 1000000))
          BETWEEN '2019-06-01' AND '2019-12-31'
),

monthly_stats AS (
    SELECT
        DATE_TRUNC('month', order_date)                     AS month_start,
        "category",
        COUNT(DISTINCT "order_id")                          AS total_orders,
        SUM("sale_price")                                   AS total_revenue,
        SUM("sale_price" - "cost")                          AS total_profit
    FROM order_items_2019
    GROUP BY month_start, "category"
),

june_baseline AS (
    SELECT
        "category",
        total_orders                                        AS june_orders,
        total_revenue                                       AS june_revenue,
        total_profit                                        AS june_profit
    FROM monthly_stats
    WHERE month_start = '2019-06-01'
),

final AS (
    SELECT
        m.month_start,
        m."category",
        m.total_orders,
        m.total_revenue,
        m.total_profit,
        ROUND((m.total_orders  - b.june_orders ) / NULLIF(b.june_orders ,0), 4) AS orders_growth_rate,
        ROUND((m.total_revenue - b.june_revenue) / NULLIF(b.june_revenue,0), 4) AS revenue_growth_rate,
        ROUND((m.total_profit  - b.june_profit ) / NULLIF(b.june_profit ,0), 4) AS profit_growth_rate
    FROM monthly_stats m
    LEFT JOIN june_baseline b
           ON m."category" = b."category"
    WHERE m.month_start >  '2019-06-01'
      AND m.month_start <= '2019-12-01'
)

SELECT
    TO_CHAR(month_start, 'YYYY-MM')        AS month,
    "category"                             AS product_category,
    total_orders,
    total_revenue,
    total_profit,
    orders_growth_rate,
    revenue_growth_rate,
    profit_growth_rate
FROM final
ORDER BY month_start ASC, "category" ASC;