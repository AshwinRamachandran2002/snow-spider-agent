/* -----------------------------------------------------------
   Monthly performance report (before 2022) by product category
   -----------------------------------------------------------
   •  Scope  : order-items whose status = 'Complete'
               and with a non-NULL delivered_at < 01-Jan-2022
   •  Grain  : product_category × delivered_month
   •  Metrics: total revenue, completed orders,
               MoM % growth (revenue & orders),
               total cost, total profit, profit / cost ratio
   ----------------------------------------------------------- */
WITH completed_items AS (
    SELECT
          p."category"                                                     AS "product_category"
        , DATE_TRUNC('month', TO_TIMESTAMP_LTZ(oi."delivered_at" / 1e6))   AS "month_start"
        , oi."sale_price"
        , p."cost"
        , oi."order_id"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"     p
          ON oi."product_id" = p."id"
    WHERE oi."status" = 'Complete'
      AND oi."delivered_at" IS NOT NULL
      AND TO_DATE(TO_TIMESTAMP_LTZ(oi."delivered_at" / 1e6)) < '2022-01-01'
),
monthly_agg AS (
    SELECT
          "product_category"
        , "month_start"
        , SUM("sale_price")                           AS "total_revenue"
        , COUNT(DISTINCT "order_id")                  AS "completed_orders"
        , SUM("cost")                                 AS "total_cost"
        , SUM("sale_price") - SUM("cost")             AS "total_profit"
    FROM completed_items
    GROUP BY "product_category", "month_start"
)

SELECT
      "product_category"
    , "month_start"
    , "total_revenue"
    , "completed_orders"
    , ROUND(
          ( "total_revenue"
            - LAG("total_revenue") OVER (PARTITION BY "product_category" ORDER BY "month_start") )
          / NULLIF(
              LAG("total_revenue") OVER (PARTITION BY "product_category" ORDER BY "month_start")
            , 0)
      , 4)                                            AS "mom_revenue_growth_pct"
    , ROUND(
          ( "completed_orders"
            - LAG("completed_orders") OVER (PARTITION BY "product_category" ORDER BY "month_start") )
          / NULLIF(
              LAG("completed_orders") OVER (PARTITION BY "product_category" ORDER BY "month_start")
            , 0)
      , 4)                                            AS "mom_orders_growth_pct"
    , "total_cost"
    , "total_profit"
    , CASE
          WHEN "total_cost" = 0 THEN NULL
          ELSE ROUND("total_profit" / "total_cost", 4)
      END                                             AS "profit_to_cost_ratio"
FROM monthly_agg
ORDER BY "product_category", "month_start";