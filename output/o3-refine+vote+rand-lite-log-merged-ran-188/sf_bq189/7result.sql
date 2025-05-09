WITH order_data AS (   -- 1. completed order lines with category & month
    SELECT
        p."category"                                                AS "category",
        DATE_TRUNC('month', TO_TIMESTAMP(oi."created_at"/1000000))  AS "month",
        oi."order_id"                                               AS "order_id",
        oi."sale_price"                                             AS "sale_price"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"     p
          ON oi."product_id" = p."id"
    WHERE oi."status" = 'Complete'
),                                                          -- 2. monthly totals
monthly_totals AS (
    SELECT
        "category",
        "month",
        COUNT(DISTINCT "order_id")        AS "orders_cnt",
        SUM("sale_price")                 AS "revenue"
    FROM order_data
    GROUP BY "category","month"
),                                                          -- 3. add previous‑month data
with_prev AS (
    SELECT
        mt.*,
        LAG("orders_cnt") OVER (PARTITION BY "category" ORDER BY "month")  AS "prev_orders_cnt",
        LAG("revenue")     OVER (PARTITION BY "category" ORDER BY "month") AS "prev_revenue"
    FROM monthly_totals mt
),                                                          -- 4. month‑to‑month growth rates
growth_rates AS (
    SELECT
        "category",
        "month",
        CASE WHEN "prev_orders_cnt" IS NULL OR "prev_orders_cnt" = 0
             THEN NULL
             ELSE ("orders_cnt" - "prev_orders_cnt") / "prev_orders_cnt"
        END AS "orders_growth",
        CASE WHEN "prev_revenue" IS NULL OR "prev_revenue" = 0
             THEN NULL
             ELSE ("revenue" - "prev_revenue") / "prev_revenue"
        END AS "revenue_growth"
    FROM with_prev
),                                                          -- 5. average order growth per category
avg_order_growth AS (
    SELECT
        "category",
        AVG("orders_growth") AS "avg_orders_growth"
    FROM growth_rates
    GROUP BY "category"
),                                                          -- 6. category with highest avg order growth
top_category AS (
    SELECT *
    FROM   avg_order_growth
    ORDER BY "avg_orders_growth" DESC NULLS LAST
    LIMIT 1
),                                                          -- 7. avg revenue growth for that category
final AS (
    SELECT
        tc."category",
        tc."avg_orders_growth",
        AVG(gr."revenue_growth") AS "avg_revenue_growth"
    FROM top_category tc
    JOIN growth_rates gr
      ON gr."category" = tc."category"
    GROUP BY tc."category", tc."avg_orders_growth"
)
SELECT
    "category",
    ROUND("avg_orders_growth"*100,4)   AS "avg_monthly_order_growth_pct",
    ROUND("avg_revenue_growth"*100,4)  AS "avg_monthly_revenue_growth_pct"
FROM final;