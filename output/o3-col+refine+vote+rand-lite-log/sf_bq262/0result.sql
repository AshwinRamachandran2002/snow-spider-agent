WITH base AS (
    /* 1.  Aggregate June-to-December 2019 performance by month and product category */
    SELECT
        TO_CHAR(TO_TIMESTAMP_NTZ(o."created_at" / 1000000), 'YYYY-MM')    AS "month",
        p."category"                                                     AS "product_category",
        COUNT(DISTINCT o."order_id")                                     AS "total_orders",
        SUM(oi."sale_price")                                             AS "total_revenue",
        SUM(oi."sale_price" - p."cost")                                  AS "total_profit"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"       o
      ON oi."order_id" = o."order_id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"     p
      ON oi."product_id" = p."id"
    WHERE TO_CHAR(TO_TIMESTAMP_NTZ(o."created_at" / 1000000), 'YYYY-MM')
          BETWEEN '2019-06' AND '2019-12'
    GROUP BY "month", "product_category"
),
with_growth AS (
    /* 2.  Bring forward prior-month metrics to compute MoM growth */
    SELECT
        "month",
        "product_category",
        "total_orders",
        "total_revenue",
        "total_profit",
        LAG("total_orders")  OVER (PARTITION BY "product_category" ORDER BY "month") AS "prior_orders",
        LAG("total_revenue") OVER (PARTITION BY "product_category" ORDER BY "month") AS "prior_revenue",
        LAG("total_profit")  OVER (PARTITION BY "product_category" ORDER BY "month") AS "prior_profit"
    FROM base
)
SELECT
    "month",
    "product_category",
    "total_orders",
    "total_revenue",
    "total_profit",
    ROUND((("total_orders"  - "prior_orders")  / NULLIF("prior_orders",  0)) * 100, 2) AS "orders_mom_growth_pct",
    ROUND((("total_revenue" - "prior_revenue") / NULLIF("prior_revenue", 0)) * 100, 2) AS "revenue_mom_growth_pct",
    ROUND((("total_profit"  - "prior_profit")  / NULLIF("prior_profit",  0)) * 100, 2) AS "profit_mom_growth_pct"
FROM with_growth
WHERE "month" >= '2019-07'     -- exclude June from the final display
ORDER BY "month", "product_category";