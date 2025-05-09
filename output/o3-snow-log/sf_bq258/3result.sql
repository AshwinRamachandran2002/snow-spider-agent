WITH base AS (   /* 1.  Pull every delivered-before-2022 line-item that belongs to a “Complete” order */
    SELECT
        p."category"                                                   AS "category",
        DATE_TRUNC('MONTH', TO_TIMESTAMP(o."delivered_at" / 1000000))  AS "month",
        oi."sale_price"                                                AS "sale_price",
        p."cost"                                                       AS "cost",
        oi."order_id"                                                  AS "order_id"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"       o  ON oi."order_id" = o."order_id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"     p  ON oi."product_id" = p."id"
    WHERE o."status" = 'Complete'
      AND o."delivered_at" IS NOT NULL
      AND TO_TIMESTAMP(o."delivered_at" / 1000000) < '2022-01-01'
), monthly AS (  /* 2.  Aggregate by category & month */
    SELECT
        "category",
        "month",
        SUM("sale_price")                          AS "total_revenue",
        COUNT(DISTINCT "order_id")                 AS "total_orders",
        SUM("cost")                                AS "total_cost"
    FROM base
    GROUP BY "category", "month"
), profit AS (   /* 3.  Add profit metrics */
    SELECT
        "category",
        "month",
        ROUND("total_revenue", 4)                                AS "total_revenue",
        "total_orders",
        ROUND("total_cost", 4)                                   AS "total_cost",
        ROUND("total_revenue" - "total_cost", 4)                 AS "total_profit",
        CASE WHEN "total_cost" <> 0
             THEN ROUND(("total_revenue" - "total_cost") / "total_cost", 4)
        END                                                      AS "profit_to_cost_ratio"
    FROM monthly
)
SELECT                                                       /* 4.  Month-over-month growth calculations */
    "category",
    TO_CHAR("month", 'YYYY-MM')                              AS "year_month",
    "total_revenue",
    "total_orders",
    "total_cost",
    "total_profit",
    "profit_to_cost_ratio",
    ROUND(
        ("total_revenue"
         - LAG("total_revenue") OVER (PARTITION BY "category" ORDER BY "month"))
        / NULLIF(LAG("total_revenue") OVER (PARTITION BY "category" ORDER BY "month"), 0)
        * 100, 4)                                             AS "revenue_mom_growth_pct",
    ROUND(
        ("total_orders"
         - LAG("total_orders") OVER (PARTITION BY "category" ORDER BY "month"))
        / NULLIF(LAG("total_orders") OVER (PARTITION BY "category" ORDER BY "month"), 0)
        * 100, 4)                                             AS "orders_mom_growth_pct"
FROM profit
ORDER BY "category", "month" ASC;