WITH completed_items AS (   -- 1. keep only completed & delivered (< 2022‑01‑01) order‑items
    SELECT
        oi."order_id",
        p."category",
        oi."sale_price",
        p."cost"           AS product_cost,
        TO_DATE(TO_TIMESTAMP(oi."delivered_at" / 1000000)) AS delivered_date
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"     oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"        p
          ON oi."product_id" = p."id"
    WHERE oi."status" = 'Complete'
      AND oi."delivered_at" IS NOT NULL
      AND TO_TIMESTAMP(oi."delivered_at" / 1000000) < '2022-01-01'
),

monthly_agg AS (            -- 2. monthly aggregation
    SELECT
        "category",
        YEAR(delivered_date)  AS yr,
        MONTH(delivered_date) AS mon,
        SUM("sale_price")                 AS total_revenue,
        COUNT(DISTINCT "order_id")        AS completed_orders,
        SUM(product_cost)                 AS total_cost
    FROM completed_items
    GROUP BY "category", yr, mon
)

SELECT                                                          -- 3. add MoM growth & profit metrics
    "category",
    yr              AS "year",
    mon             AS "month",
    total_revenue,
    completed_orders,
    ROUND(
        (total_revenue
         - LAG(total_revenue) OVER (PARTITION BY "category" ORDER BY yr, mon))
        / NULLIF(LAG(total_revenue) OVER (PARTITION BY "category" ORDER BY yr, mon), 0)
        * 100, 4)                           AS revenue_mom_growth_pct,
    ROUND(
        (completed_orders
         - LAG(completed_orders) OVER (PARTITION BY "category" ORDER BY yr, mon))
        / NULLIF(LAG(completed_orders) OVER (PARTITION BY "category" ORDER BY yr, mon), 0)
        * 100, 4)                           AS orders_mom_growth_pct,
    total_cost,
    (total_revenue - total_cost)            AS profit,
    CASE
        WHEN total_cost = 0 THEN NULL
        ELSE ROUND((total_revenue - total_cost) / total_cost, 4)
    END                                      AS profit_to_cost_ratio
FROM monthly_agg
ORDER BY "category", yr, mon;