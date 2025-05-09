WITH completed_orders AS (      -- 1. keep only completed order‑items
    SELECT 
        "oi"."order_id",
        "oi"."product_id",
        "oi"."sale_price",
        DATE_TRUNC('month',
                   TO_TIMESTAMP_NTZ("oi"."created_at" / 1e6)
                  )                         AS "order_month"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  AS "oi"
    WHERE "oi"."status" = 'Complete'
), 

orders_by_cat_month AS (        -- 2. number of distinct orders & revenue per category‑month
    SELECT 
        "p"."category"                          AS "category",
        "c"."order_month",
        COUNT(DISTINCT "c"."order_id")          AS "orders_cnt",
        SUM("c"."sale_price")                   AS "revenue"
    FROM completed_orders  AS "c"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS" AS "p"
      ON "p"."id" = "c"."product_id"
    GROUP BY "category", "order_month"
), 

cat_month_with_lags AS (        -- 3. add previous‑month values
    SELECT
        "category",
        "order_month",
        "orders_cnt",
        LAG("orders_cnt")  OVER (PARTITION BY "category" ORDER BY "order_month") AS "prev_orders_cnt",
        "revenue",
        LAG("revenue")     OVER (PARTITION BY "category" ORDER BY "order_month") AS "prev_revenue"
    FROM orders_by_cat_month
), 

avg_order_growth AS (           -- 4. average monthly % growth of order count per category
    SELECT
        "category",
        AVG( ("orders_cnt" - "prev_orders_cnt") / NULLIF("prev_orders_cnt",0) ) AS "avg_monthly_order_growth"
    FROM cat_month_with_lags
    WHERE "prev_orders_cnt" IS NOT NULL      -- need a previous month
          AND "prev_orders_cnt" <> 0         -- avoid divide‑by‑zero
    GROUP BY "category"
), 

top_cat AS (                    -- 5. category with the highest avg growth in orders
    SELECT 
        "category",
        "avg_monthly_order_growth"
    FROM   avg_order_growth
    QUALIFY ROW_NUMBER() OVER (ORDER BY "avg_monthly_order_growth" DESC) = 1
), 

avg_revenue_growth AS (         -- 6. average monthly % growth of revenue for that category
    SELECT
        "cml"."category",
        AVG( ("cml"."revenue" - "cml"."prev_revenue") / NULLIF("cml"."prev_revenue",0) )
            AS "avg_monthly_revenue_growth"
    FROM cat_month_with_lags AS "cml"
    JOIN top_cat             AS "tc"
      ON "cml"."category" = "tc"."category"
    WHERE "cml"."prev_revenue" IS NOT NULL
          AND "cml"."prev_revenue" <> 0
    GROUP BY "cml"."category"
)

SELECT
    "tc"."category"                                                     AS "product_category_with_highest_order_growth",
    ROUND("tc"."avg_monthly_order_growth",    4)  AS "avg_monthly_order_growth_rate",
    ROUND("arg"."avg_monthly_revenue_growth", 4)  AS "avg_monthly_revenue_growth_rate"
FROM top_cat           AS "tc"
JOIN avg_revenue_growth AS "arg"
  ON "arg"."category" = "tc"."category";