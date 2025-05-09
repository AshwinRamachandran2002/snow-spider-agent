/*  Monthly performance report (before 2022) for every product category.
    – Only order-items whose status = 'Complete' and that have a non-NULL
      delivered_at < 2022-01-01 are considered.
    – Micro-second timestamps are converted to month granularity.
    – MoM % growth is calculated with window functions.
*/

WITH completed_items AS (   -- 1) pick the relevant order-items
    SELECT
        pr."category",
        DATE_TRUNC(
            'month',
            TO_TIMESTAMP_NTZ(oi."delivered_at" / 1000000)   -- µs → TIMESTAMP
        )                           AS "month_date",
        oi."sale_price"             AS "revenue",
        ii."cost"                   AS "unit_cost"
    FROM "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS"      oi
    JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."INVENTORY_ITEMS"  ii
          ON ii."id" = oi."inventory_item_id"
    JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."PRODUCTS"         pr
          ON pr."id" = oi."product_id"
    WHERE oi."status"        = 'Complete'
      AND oi."delivered_at" IS NOT NULL
      AND oi."delivered_at"  < 1640995200000000        -- 2022-01-01 00:00:00
),

aggregated AS (            -- 2) monthly roll-up
    SELECT
        "category",
        "month_date",
        SUM("revenue")    AS "total_revenue",
        COUNT(*)          AS "completed_orders",
        SUM("unit_cost")  AS "total_cost"
    FROM completed_items
    GROUP BY "category", "month_date"
),

metrics AS (               -- 3) add MoM growth & profit metrics
    SELECT
        "category",
        TO_CHAR("month_date", 'YYYY-MM')                 AS "year_month",
        "total_revenue",
        "completed_orders",
        ROUND(
            ( "total_revenue"
              - LAG("total_revenue") OVER (PARTITION BY "category"
                                            ORDER BY "month_date") )
            / NULLIF( LAG("total_revenue") OVER (PARTITION BY "category"
                                                 ORDER BY "month_date"), 0)
            * 100,
        4)                                                AS "revenue_mom_growth_pct",
        ROUND(
            ( "completed_orders"
              - LAG("completed_orders") OVER (PARTITION BY "category"
                                             ORDER BY "month_date") )
            / NULLIF( LAG("completed_orders") OVER (PARTITION BY "category"
                                                    ORDER BY "month_date"), 0)
            * 100,
        4)                                                AS "orders_mom_growth_pct",
        "total_cost",
        ("total_revenue" - "total_cost")                 AS "total_profit",
        ROUND( ("total_revenue" - "total_cost")
               / NULLIF("total_cost",0), 4)              AS "profit_to_cost_ratio"
    FROM aggregated
)

SELECT *
FROM metrics
ORDER BY "category", "year_month";