WITH "order_data" AS (   -- raw order‑item rows June‑Dec 2019
    SELECT
        TO_CHAR(TO_TIMESTAMP("OI"."created_at" / 1000000), 'YYYY-MM')           AS "month",
        "P"."category"                                                         AS "product_category",
        "OI"."order_id"                                                        AS "order_id",
        "OI"."sale_price"                                                      AS "sale_price",
        "P"."cost"                                                             AS "unit_cost"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  AS "OI"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"     AS "P"
          ON "OI"."product_id" = "P"."id"
    WHERE TO_TIMESTAMP("OI"."created_at" / 1000000) >= '2019-06-01'
      AND TO_TIMESTAMP("OI"."created_at" / 1000000) <  '2020-01-01'
),
"aggregated" AS (        -- monthly category totals
    SELECT
        "month",
        "product_category",
        COUNT(DISTINCT "order_id")                             AS "total_orders",
        SUM("sale_price")                                      AS "total_revenue",
        SUM("sale_price" - "unit_cost")                        AS "total_profit"
    FROM "order_data"
    GROUP BY "month", "product_category"
),
"with_lag" AS (          -- bring previous‑month values per category
    SELECT
        "month",
        "product_category",
        "total_orders",
        "total_revenue",
        "total_profit",
        LAG("total_orders")  OVER (PARTITION BY "product_category" ORDER BY "month") AS "prev_orders",
        LAG("total_revenue") OVER (PARTITION BY "product_category" ORDER BY "month") AS "prev_revenue",
        LAG("total_profit")  OVER (PARTITION BY "product_category" ORDER BY "month") AS "prev_profit"
    FROM "aggregated"
),
"final" AS (             -- calculate MoM growth
    SELECT
        "month",
        "product_category",
        "total_orders",
        "total_revenue",
        "total_profit",
        CASE WHEN "prev_orders"  IS NOT NULL AND "prev_orders"  <> 0
             THEN ("total_orders"  - "prev_orders")  / "prev_orders"
        END                                                   AS "orders_mom_growth",
        CASE WHEN "prev_revenue" IS NOT NULL AND "prev_revenue" <> 0
             THEN ("total_revenue" - "prev_revenue") / "prev_revenue"
        END                                                   AS "revenue_mom_growth",
        CASE WHEN "prev_profit"  IS NOT NULL AND "prev_profit"  <> 0
             THEN ("total_profit"  - "prev_profit")  / "prev_profit"
        END                                                   AS "profit_mom_growth"
    FROM "with_lag"
)
SELECT
    "month",
    "product_category",
    "total_orders",
    "total_revenue",
    "total_profit",
    "orders_mom_growth",
    "revenue_mom_growth",
    "profit_mom_growth"
FROM "final"
WHERE "month" BETWEEN '2019-07' AND '2019-12'   -- omit June from output
ORDER BY "month", "product_category";