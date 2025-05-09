WITH completed_deliveries AS (   -- 1. pick only completed, pre-2022, delivered order items
    SELECT
        OI."order_id",
        OI."product_id",
        OI."sale_price",
        P."category"                    AS "product_category",
        P."cost"                        AS "product_cost",
        DATE_TRUNC(
            'month',
            TO_TIMESTAMP_LTZ(OI."delivered_at" / 1000000)   -- delivered_at is stored in µs
        )                               AS "delivery_month"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  OI
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"     P
          ON OI."product_id" = P."id"
    WHERE OI."status" = 'Complete'
      AND OI."delivered_at" IS NOT NULL
      AND TO_TIMESTAMP_LTZ(OI."delivered_at" / 1000000) < '2022-01-01'
),

monthly_agg AS (                   -- 2. aggregate by category & month
    SELECT
        "product_category",
        "delivery_month",
        SUM("sale_price")                             AS "total_revenue",
        COUNT(DISTINCT "order_id")                    AS "total_orders",
        SUM("product_cost")                           AS "total_cost",
        SUM("sale_price") - SUM("product_cost")       AS "total_profit"
    FROM completed_deliveries
    GROUP BY "product_category", "delivery_month"
),

with_growth AS (                   -- 3. add MoM values via window functions
    SELECT
        "product_category",
        "delivery_month",
        "total_revenue",
        "total_orders",
        "total_cost",
        "total_profit",
        "total_profit" / NULLIF("total_cost",0)                       AS "profit_to_cost_ratio",
        LAG("total_revenue") OVER (PARTITION BY "product_category"
                                   ORDER BY "delivery_month")         AS "prev_revenue",
        LAG("total_orders")  OVER (PARTITION BY "product_category"
                                   ORDER BY "delivery_month")         AS "prev_orders"
    FROM monthly_agg
)

SELECT
    "product_category",
    TO_CHAR("delivery_month",'YYYY')                     AS "year",
    TO_CHAR("delivery_month",'MM')                       AS "month",
    "total_revenue",
    "total_orders",
    ROUND( ( "total_revenue" - "prev_revenue")
           / NULLIF("prev_revenue",0) * 100 , 4)         AS "revenue_mom_growth_pct",
    ROUND( ( "total_orders"  - "prev_orders")
           / NULLIF("prev_orders",0)  * 100 , 4)         AS "orders_mom_growth_pct",
    "total_cost",
    "total_profit",
    ROUND("profit_to_cost_ratio", 4)                     AS "profit_to_cost_ratio"
FROM with_growth
ORDER BY
    "product_category",
    "delivery_month" NULLS LAST;