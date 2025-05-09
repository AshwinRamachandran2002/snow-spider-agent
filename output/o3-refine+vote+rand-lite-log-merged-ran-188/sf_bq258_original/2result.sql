WITH delivered_items AS (   -- 1. completed items delivered before 2022‑01‑01
    SELECT
        oi."order_id"                    AS order_id,
        oi."product_id"                  AS product_id,
        oi."sale_price"                  AS sale_price,
        TO_TIMESTAMP(oi."delivered_at" / 1000000)   AS delivered_ts
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"       o
          ON oi."order_id" = o."order_id"
    WHERE oi."status"  = 'Complete'
      AND o."status"   = 'Complete'
      AND oi."delivered_at" IS NOT NULL
      AND TO_TIMESTAMP(oi."delivered_at" / 1000000) < '2022-01-01'
),
items_with_cost AS (        -- 2. attach product category & unit‑cost
    SELECT
        di.order_id,
        di.sale_price,
        di.delivered_ts,
        p."category"                            AS category,
        p."cost"                                AS unit_cost
    FROM delivered_items di
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS" p
         ON di.product_id = p."id"
),
monthly_rollup AS (         -- 3. aggregate by category & month
    SELECT
        category,
        DATE_TRUNC('MONTH', delivered_ts)::DATE AS month_start,
        SUM(sale_price)                         AS total_revenue,
        COUNT(DISTINCT order_id)                AS total_orders,
        SUM(unit_cost)                          AS total_cost
    FROM items_with_cost
    GROUP BY category, month_start
),
profit_calc AS (            -- 4. add profit column
    SELECT  *,
            total_revenue - total_cost          AS total_profit
    FROM    monthly_rollup
),
final AS (                  -- 5. MoM % growth & profit‑to‑cost ratio
    SELECT
        category,
        month_start,
        total_revenue,
        total_orders,
        total_cost,
        total_profit,
        ROUND(
            (total_revenue - LAG(total_revenue) OVER (PARTITION BY category ORDER BY month_start))
            / NULLIF(LAG(total_revenue) OVER (PARTITION BY category ORDER BY month_start),0) * 100
        ,4)                                                    AS revenue_mom_growth_pct,
        ROUND(
            (total_orders - LAG(total_orders) OVER (PARTITION BY category ORDER BY month_start))
            / NULLIF(LAG(total_orders) OVER (PARTITION BY category ORDER BY month_start),0) * 100
        ,4)                                                    AS orders_mom_growth_pct,
        ROUND(
            total_profit / NULLIF(total_cost,0)
        ,4)                                                    AS profit_to_cost_ratio
    FROM profit_calc
)
SELECT *
FROM final
ORDER BY category, month_start;