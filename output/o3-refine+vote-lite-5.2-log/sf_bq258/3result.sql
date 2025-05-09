/*  Monthly report (up to, but not including, 2022) for each product category.
    - Only order‑items whose own status = 'Complete' and that have a non‑null delivered_at
      timestamp earlier than 1‑Jan‑2022 are considered.
    - Dates in the tables are stored as micro‑seconds since Unix epoch, so divide by 1 000 000
      before converting to TIMESTAMP in Snowflake.
*/

WITH delivered_items AS (
    SELECT
        oi."order_id",
        oi."product_id",
        oi."sale_price",
        oi."delivered_at",
        p."category",
        p."cost"               AS product_cost,
        /* convert micro‑seconds epoch to Snowflake TIMESTAMP */
        TO_TIMESTAMP(oi."delivered_at" / 1000000) AS delivered_ts
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"     p
          ON p."id" = oi."product_id"
    WHERE oi."status"        = 'Complete'
      AND oi."delivered_at" IS NOT NULL
      AND TO_TIMESTAMP(oi."delivered_at" / 1000000) < '2022-01-01'   -- before 2022
),

monthly_base AS (
    SELECT
        "category",
        DATE_TRUNC('month', delivered_ts)          AS month_start,   -- first‑day‑of‑month
        SUM("sale_price")                          AS revenue,
        COUNT(DISTINCT "order_id")                 AS completed_orders,
        SUM(product_cost)                          AS total_cost
    FROM delivered_items
    GROUP BY "category", DATE_TRUNC('month', delivered_ts)
)

SELECT
    "category",
    TO_CHAR(month_start, 'YYYY‑MM')                                    AS year_month,
    revenue,
    completed_orders,

    /* month‑over‑month % growth – revenue */
    ROUND(
        100 * (revenue - LAG(revenue) OVER (PARTITION BY "category" ORDER BY month_start))
            / NULLIF(LAG(revenue) OVER (PARTITION BY "category" ORDER BY month_start), 0)
        , 4
    )                                                                 AS revenue_mom_growth_pct,

    /* month‑over‑month % growth – orders */
    ROUND(
        100 * (completed_orders - LAG(completed_orders) OVER (PARTITION BY "category" ORDER BY month_start))
            / NULLIF(LAG(completed_orders) OVER (PARTITION BY "category" ORDER BY month_start), 0)
        , 4
    )                                                                 AS orders_mom_growth_pct,

    total_cost,
    (revenue - total_cost)                                            AS profit,
    CASE 
        WHEN total_cost <> 0 THEN ROUND((revenue - total_cost) / total_cost, 4)
        ELSE NULL
    END                                                               AS profit_to_cost_ratio
FROM monthly_base
ORDER BY "category", month_start;