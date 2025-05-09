WITH "monthly" AS (
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP("oi"."created_at" / 1e6)) AS "month",
        "p"."category"                                             AS "category",
        COUNT(DISTINCT "oi"."order_id")                            AS "unique_orders",
        SUM("oi"."sale_price")                                     AS "revenue"
    FROM "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS"   AS "oi"
    JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."PRODUCTS"      AS "p"
      ON "oi"."product_id" = "p"."id"
    WHERE "oi"."status" = 'Complete'
    GROUP BY "month", "category"
),
"order_growth" AS (
    SELECT
        "category",
        "month",
        100.0 * ("unique_orders" - LAG("unique_orders") OVER (PARTITION BY "category" ORDER BY "month"))
              / NULLIF(LAG("unique_orders") OVER (PARTITION BY "category" ORDER BY "month"), 0)
              AS "pct_order_growth"
    FROM "monthly"
),
"category_avg_order_growth" AS (
    SELECT
        "category",
        AVG("pct_order_growth") AS "avg_pct_order_growth"
    FROM "order_growth"
    GROUP BY "category"
),
"top_category" AS (
    SELECT
        "category",
        "avg_pct_order_growth",
        ROW_NUMBER() OVER (ORDER BY "avg_pct_order_growth" DESC) AS "rk"
    FROM "category_avg_order_growth"
),
"revenue_growth" AS (
    SELECT
        m."category",
        m."month",
        100.0 * (m."revenue" - LAG(m."revenue") OVER (PARTITION BY m."category" ORDER BY m."month"))
              / NULLIF(LAG(m."revenue") OVER (PARTITION BY m."category" ORDER BY m."month"), 0)
              AS "pct_revenue_growth"
    FROM "monthly" AS m
    JOIN "top_category" AS t
      ON m."category" = t."category"
    WHERE t."rk" = 1
),
"final_revenue_avg" AS (
    SELECT
        "category",
        AVG("pct_revenue_growth") AS "avg_pct_revenue_growth"
    FROM "revenue_growth"
    GROUP BY "category"
)
SELECT
    t."category"                                   AS "top_category",
    ROUND(t."avg_pct_order_growth",   4)           AS "avg_monthly_order_growth_pct",
    ROUND(r."avg_pct_revenue_growth", 4)           AS "avg_monthly_revenue_growth_pct"
FROM "top_category"      AS t
JOIN "final_revenue_avg" AS r
  ON t."category" = r."category"
WHERE t."rk" = 1;