/* -----------------------------------------------------------
   Monthly performance by product category for orders that are
   1) marked as 'Complete'
   2) delivered before 01-Jan-2022
   ----------------------------------------------------------- */
WITH base AS (
    /* Pull every delivered order-item together with its category & cost */
    SELECT
        oi."order_id",
        oi."sale_price",
        p."cost"                          AS "product_cost",
        p."category"                      AS "product_category",
        DATE_TRUNC(
            'month',
            TO_TIMESTAMP_NTZ(oi."delivered_at" / 1000000)   -- micro-seconds ➜ seconds
        )                                 AS "delivery_month"
    FROM   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  oi
    JOIN   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"       o
           ON o."order_id" = oi."order_id"
    JOIN   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"     p
           ON p."id" = oi."product_id"
    WHERE  oi."status"        = 'Complete'
      AND  o."status"         = 'Complete'
      AND  oi."delivered_at"  IS NOT NULL
      AND  oi."delivered_at"  < 1640995200000000              -- before 2022-01-01
),
monthly AS (
    /* Aggregate revenue, orders, cost per category & month */
    SELECT
        "product_category",
        "delivery_month",
        SUM("sale_price")            AS "total_revenue",
        COUNT(DISTINCT "order_id")   AS "total_orders",
        SUM("product_cost")          AS "total_cost"
    FROM   base
    GROUP  BY "product_category", "delivery_month"
),
enriched AS (
    /* Add profit, ratios, and previous-month values */
    SELECT
        "product_category",
        "delivery_month",
        "total_revenue",
        "total_orders",
        "total_cost",
        ("total_revenue" - "total_cost")                       AS "total_profit",
        CASE WHEN "total_cost" <> 0
             THEN ("total_revenue" - "total_cost") / "total_cost"
        END                                                    AS "profit_to_cost_ratio",
        LAG("total_revenue") OVER (PARTITION BY "product_category"
                                   ORDER BY "delivery_month")  AS "prev_revenue",
        LAG("total_orders")  OVER (PARTITION BY "product_category"
                                   ORDER BY "delivery_month")  AS "prev_orders"
    FROM   monthly
)
SELECT
    "product_category",
    "delivery_month"                                           AS "month_start",
    "total_revenue",
    "total_orders",
    /* MoM % growth for revenue */
    CASE
        WHEN "prev_revenue" IS NULL OR "prev_revenue" = 0
        THEN NULL
        ELSE ROUND( (("total_revenue" - "prev_revenue") / "prev_revenue") * 100 , 4)
    END                                                        AS "revenue_mom_growth_pct",
    /* MoM % growth for order count */
    CASE
        WHEN "prev_orders" IS NULL OR "prev_orders" = 0
        THEN NULL
        ELSE ROUND( (("total_orders" - "prev_orders") / "prev_orders") * 100 , 4)
    END                                                        AS "orders_mom_growth_pct",
    "total_cost",
    "total_profit",
    ROUND("profit_to_cost_ratio", 4)                           AS "profit_to_cost_ratio"
FROM   enriched
ORDER BY
    "product_category",
    "month_start";