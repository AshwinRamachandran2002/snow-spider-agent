WITH monthly_metrics AS (   -- 1.  Aggregate June–December 2019 numbers
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP_NTZ("O"."created_at" / 1000000))      AS "month_start",
        "P"."category"                                                         AS "product_category",
        COUNT(DISTINCT "O"."order_id")                                         AS "total_orders",
        SUM("OI"."sale_price")                                                 AS "total_revenue",
        SUM("OI"."sale_price" - "P"."cost")                                    AS "total_profit"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"        AS  "O"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"   AS  "OI"
          ON "OI"."order_id" = "O"."order_id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"      AS  "P"
          ON "P"."id" = "OI"."product_id"
    WHERE DATE_TRUNC('month', TO_TIMESTAMP_NTZ("O"."created_at" / 1000000))
          BETWEEN '2019-06-01' AND '2019-12-01'          -- keep June‑Dec for growth calc
    GROUP BY
        "month_start",
        "product_category"
),
metrics_with_growth AS (    -- 2.  Add month‑over‑month growth (June is the baseline)
    SELECT
        "month_start",
        "product_category",
        "total_orders",
        "total_revenue",
        "total_profit",
        LAG("total_orders")  OVER (PARTITION BY "product_category" ORDER BY "month_start") AS "prev_orders",
        LAG("total_revenue") OVER (PARTITION BY "product_category" ORDER BY "month_start") AS "prev_revenue",
        LAG("total_profit")  OVER (PARTITION BY "product_category" ORDER BY "month_start") AS "prev_profit"
    FROM monthly_metrics
)
SELECT                                                          -- 3.  Final output (omit June)
    TO_CHAR("month_start", 'YYYY-MM')                                                AS "month",
    "product_category",
    "total_orders",
    "total_revenue",
    "total_profit",
    CASE WHEN "prev_orders"  > 0 THEN ("total_orders"  - "prev_orders")  / "prev_orders"  ELSE NULL END AS "orders_mom_growth",
    CASE WHEN "prev_revenue" > 0 THEN ("total_revenue" - "prev_revenue") / "prev_revenue" ELSE NULL END AS "revenue_mom_growth",
    CASE WHEN "prev_profit"  > 0 THEN ("total_profit"  - "prev_profit")  / "prev_profit"  ELSE NULL END AS "profit_mom_growth"
FROM metrics_with_growth
WHERE "month_start" >= '2019-07-01'                             -- exclude June from results
ORDER BY
    "month_start" ASC,
    "product_category" ASC;