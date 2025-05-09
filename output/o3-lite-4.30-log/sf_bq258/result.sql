WITH filtered_items AS (
    SELECT
        p."category",
        oi."order_id",
        oi."sale_price",
        p."cost",
        DATE_TRUNC('month', TO_TIMESTAMP(oi."delivered_at" / 1000000)) AS "month_date"
    FROM "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS"  oi
    JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."PRODUCTS"     p
          ON oi."product_id" = p."id"
    WHERE oi."status" = 'Complete'
      AND oi."delivered_at" IS NOT NULL
      AND oi."delivered_at" < 1640995200000000      -- before 2022‑01‑01
), monthly AS (
    SELECT
        "category",
        EXTRACT(year  FROM "month_date")               AS "year",
        EXTRACT(month FROM "month_date")               AS "month",
        SUM("sale_price")                              AS "total_revenue",
        COUNT(DISTINCT "order_id")                     AS "total_orders",
        SUM("cost")                                    AS "total_cost"
    FROM filtered_items
    GROUP BY "category", "year", "month"
)
SELECT
    "category",
    "year",
    "month",
    ROUND("total_revenue", 4)                                            AS "total_revenue",
    "total_orders",
    ROUND(
        100 * ( "total_revenue"
                - LAG("total_revenue") OVER (PARTITION BY "category" ORDER BY "year","month") )
        / NULLIF( LAG("total_revenue") OVER (PARTITION BY "category" ORDER BY "year","month"), 0 )
    , 4)                                                                 AS "revenue_mom_growth_pct",
    ROUND(
        100 * ( "total_orders"
                - LAG("total_orders") OVER (PARTITION BY "category" ORDER BY "year","month") )
        / NULLIF( LAG("total_orders") OVER (PARTITION BY "category" ORDER BY "year","month"), 0 )
    , 4)                                                                 AS "orders_mom_growth_pct",
    ROUND("total_cost", 4)                                               AS "total_cost",
    ROUND("total_revenue" - "total_cost", 4)                             AS "total_profit",
    ROUND( ("total_revenue" - "total_cost") / NULLIF("total_cost", 0), 4) AS "profit_to_cost_ratio"
FROM monthly
ORDER BY "category", "year", "month";