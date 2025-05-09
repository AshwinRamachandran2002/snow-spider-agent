/*  Monthly performance per product category (orders delivered before 2022 & status = 'Complete')  */
WITH completed_items AS (
    SELECT
        p."category",
        DATE_TRUNC('month', TO_TIMESTAMP_NTZ(oi."delivered_at" / 1000000)) AS "delivered_month",
        oi."sale_price",
        p."cost",
        oi."order_id"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  AS oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"      AS p
          ON p."id" = oi."product_id"
    WHERE oi."status" = 'Complete'
      AND oi."delivered_at" IS NOT NULL
      AND TO_CHAR(TO_TIMESTAMP_NTZ(oi."delivered_at" / 1000000), 'YYYY') < '2022'
), monthly_agg AS (
    SELECT
        "category",
        "delivered_month",
        SUM("sale_price")                        AS "total_revenue",
        COUNT(DISTINCT "order_id")               AS "completed_orders",
        SUM("cost")                              AS "total_cost",
        SUM("sale_price") - SUM("cost")          AS "profit"
    FROM completed_items
    GROUP BY "category", "delivered_month"
)
SELECT
    "category",
    TO_CHAR("delivered_month", 'YYYY-MM')                                   AS "year_month",
    "total_revenue",
    "completed_orders",
    "total_cost",
    "profit",
    /* Month-over-month % change in revenue */
    ROUND(
        100 * (
            "total_revenue"
            - LAG("total_revenue") OVER (PARTITION BY "category" ORDER BY "delivered_month")
        )
        / NULLIF(LAG("total_revenue") OVER (PARTITION BY "category" ORDER BY "delivered_month"), 0)
    , 2)                                                                    AS "mom_revenue_growth_pct",
    /* Month-over-month % change in order count */
    ROUND(
        100 * (
            "completed_orders"
            - LAG("completed_orders") OVER (PARTITION BY "category" ORDER BY "delivered_month")
        )
        / NULLIF(LAG("completed_orders") OVER (PARTITION BY "category" ORDER BY "delivered_month"), 0)
    , 2)                                                                    AS "mom_order_growth_pct",
    CASE
        WHEN "total_cost" = 0 THEN NULL
        ELSE ROUND("profit" / "total_cost", 4)
    END                                                                     AS "profit_to_cost_ratio"
FROM monthly_agg
ORDER BY "category", "year_month";