WITH monthly_base AS (
    /* ------------------------------------------------------------
       1.  Assemble every completed order that was delivered
           BEFORE 1‑Jan‑2022 and explode it down to the item level
    -------------------------------------------------------------*/
    SELECT
        p."category"                               AS "product_category",
        DATE_TRUNC(
            'month',
            TO_TIMESTAMP_NTZ(o."delivered_at" / 1000000)   /* micro‑seconds ➜ seconds */
        )                                              AS "month_start",
        SUM(oi."sale_price")                          AS "total_revenue",
        COUNT(DISTINCT o."order_id")                  AS "total_orders",
        SUM(p."cost")                                 AS "total_cost"
    FROM  THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS        o
    JOIN  THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS   oi
           ON oi."order_id" = o."order_id"
    JOIN  THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.PRODUCTS      p
           ON p."id"       = oi."product_id"
    WHERE  o."status"        = 'Complete'
      AND  o."delivered_at" IS NOT NULL
      AND  TO_DATE(TO_TIMESTAMP_NTZ(o."delivered_at" / 1000000))
           < DATE '2022-01-01'
    GROUP BY
        p."category",
        DATE_TRUNC(
            'month',
            TO_TIMESTAMP_NTZ(o."delivered_at" / 1000000)
        )
),
monthly_enriched AS (
    /* ------------------------------------------------------------
       2.  Add profit figures and capture prior‑month values
           (per category) for MoM growth calculations
    -------------------------------------------------------------*/
    SELECT
        "product_category",
        "month_start",
        "total_revenue",
        "total_orders",
        "total_cost",
        ("total_revenue" - "total_cost")                      AS "total_profit",
        ("total_revenue" - "total_cost") /
            NULLIF("total_cost",0)                           AS "profit_to_cost_ratio",
        LAG("total_revenue") OVER (
            PARTITION BY "product_category"
            ORDER BY "month_start"
        )                                                    AS "prev_revenue",
        LAG("total_orders")  OVER (
            PARTITION BY "product_category"
            ORDER BY "month_start"
        )                                                    AS "prev_orders"
    FROM monthly_base
)
SELECT
    "product_category",
    "month_start",
    "total_revenue",
    "total_orders",
    ROUND( ( "total_revenue" - "prev_revenue") /
           NULLIF("prev_revenue",0), 4)                      AS "revenue_mom_growth_pct",
    ROUND( ( "total_orders"  - "prev_orders")  /
           NULLIF("prev_orders",0), 4)                       AS "orders_mom_growth_pct",
    "total_cost",
    "total_profit",
    "profit_to_cost_ratio"
FROM   monthly_enriched
ORDER BY
    "product_category",
    "month_start";