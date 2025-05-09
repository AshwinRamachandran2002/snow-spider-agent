WITH monthly_base AS (
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP_NTZ(OI."delivered_at" / 1000000)) AS "month_start",
        P."category"                                                      AS "category",
        SUM(OI."sale_price")                                              AS "total_revenue",
        COUNT(DISTINCT OI."order_id")                                     AS "total_orders",
        SUM(P."cost")                                                     AS "total_cost"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS  OI
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.PRODUCTS     P
      ON OI."product_id" = P."id"
    WHERE OI."status" = 'Complete'
      AND TO_DATE(TO_TIMESTAMP_NTZ(OI."delivered_at" / 1000000)) < '2022-01-01'
      AND OI."delivered_at" IS NOT NULL
    GROUP BY 1, 2
)

SELECT
    "category"                                                                                        AS category,
    YEAR("month_start")                                                                               AS year,
    MONTH("month_start")                                                                              AS month,
    ROUND("total_revenue", 4)                                                                         AS total_revenue,
    "total_orders",
    ROUND(
        ( "total_revenue"
          / NULLIF(LAG("total_revenue") OVER (PARTITION BY "category" ORDER BY "month_start"), 0) - 1
        ) * 100, 4)                                                                                   AS revenue_mom_growth_pct,
    ROUND(
        ( "total_orders"
          / NULLIF(LAG("total_orders") OVER (PARTITION BY "category" ORDER BY "month_start"), 0) - 1
        ) * 100, 4)                                                                                   AS orders_mom_growth_pct,
    ROUND("total_cost", 4)                                                                            AS total_cost,
    ROUND("total_revenue" - "total_cost", 4)                                                          AS total_profit,
    ROUND(
        ("total_revenue" - "total_cost") / NULLIF("total_cost", 0), 4)                                AS profit_to_cost_ratio
FROM monthly_base
ORDER BY category, year, month;