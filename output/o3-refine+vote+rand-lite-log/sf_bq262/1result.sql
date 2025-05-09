/*  Monthly category‑level sales report with MoM growth
    Period analysed : 2019‑06  – 2019‑12
    Output          : 2019‑07 – 2019‑12 (June kept only for growth baseline)
*/

WITH order_items_extended AS (   -- enrich order items with month & product category
    SELECT
        TO_CHAR(DATE_TRUNC('month', TO_TIMESTAMP("created_at" / 1e6)), 'YYYY-MM')      AS "month",
        p."category"                                                                  AS "category",
        "order_id",
        "sale_price",
        p."cost"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS        oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.PRODUCTS           p
          ON oi."product_id" = p."id"
    WHERE DATE_TRUNC('month', TO_TIMESTAMP(oi."created_at" / 1e6))
          BETWEEN DATE '2019-06-01' AND DATE '2019-12-01'
),

monthly_metrics AS (             -- aggregate per month & category
    SELECT
        "month",
        "category",
        COUNT(DISTINCT "order_id")                           AS "total_orders",
        SUM("sale_price")                                    AS "total_revenue",
        SUM("sale_price" - "cost")                           AS "total_profit"
    FROM order_items_extended
    GROUP BY "month", "category"
),

metrics_with_growth AS (         -- add MoM growth using window LAG
    SELECT
        "month",
        "category",
        "total_orders",
        "total_revenue",
        "total_profit",
        /* growth = (current – previous) / previous */
        ("total_orders"  - LAG("total_orders")  OVER (PARTITION BY "category" ORDER BY "month"))
            / NULLIF(LAG("total_orders")  OVER (PARTITION BY "category" ORDER BY "month"), 0)  AS "orders_mom_growth",
        ("total_revenue" - LAG("total_revenue") OVER (PARTITION BY "category" ORDER BY "month"))
            / NULLIF(LAG("total_revenue") OVER (PARTITION BY "category" ORDER BY "month"), 0)  AS "revenue_mom_growth",
        ("total_profit"  - LAG("total_profit")  OVER (PARTITION BY "category" ORDER BY "month"))
            / NULLIF(LAG("total_profit")  OVER (PARTITION BY "category" ORDER BY "month"), 0)  AS "profit_mom_growth"
    FROM monthly_metrics
)

SELECT
    "month",
    "category",
    "total_orders",
    "total_revenue",
    "total_profit",
    "orders_mom_growth",
    "revenue_mom_growth",
    "profit_mom_growth"
FROM metrics_with_growth
WHERE "month" > '2019-06'                 -- omit June from final output
ORDER BY
    TO_DATE("month" || '-01') ASC,        -- chronological order
    "category" ASC;