/* --------------------------------------------------------------
   1)  Gather monthly metrics (unique-orders & revenue) per category
   2)  Compute month-over-month %-growth in UNIQUE ORDERS
   3)  Average those growth rates ⇒ pick the category with the HIGHEST average
   4)  For that winning category, compute month-over-month %-growth in REVENUE
       and take the average
   5)  Return both averages for the winning product category
-----------------------------------------------------------------*/
WITH monthly_metrics AS (   -- step-1
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP(oi."created_at" / 1000000))   AS "month",
        p."category"                                                  AS "category",
        COUNT(DISTINCT oi."order_id")                                 AS "unique_orders",
        SUM(oi."sale_price")                                          AS "revenue"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"     p
           ON oi."product_id" = p."id"
    WHERE oi."status" = 'Complete'
    GROUP BY 1, 2
),

/* -------- average MONTH-OVER-MONTH % growth in UNIQUE ORDERS ------- */
order_growth AS (
    SELECT
        "category",
        ("unique_orders" - LAG("unique_orders") OVER (PARTITION BY "category" ORDER BY "month"))
        / NULLIF(LAG("unique_orders") OVER (PARTITION BY "category" ORDER BY "month"), 0) * 100
        AS "pct_order_growth"
    FROM monthly_metrics
),
avg_order_growth AS (
    SELECT
        "category",
        AVG("pct_order_growth") AS "avg_monthly_order_growth_pct"
    FROM order_growth
    WHERE "pct_order_growth" IS NOT NULL
    GROUP BY "category"
),

/* -------- pick the category with the HIGHEST avg order-growth ------ */
top_cat AS (
    SELECT
        "category",
        "avg_monthly_order_growth_pct",
        ROW_NUMBER() OVER (ORDER BY "avg_monthly_order_growth_pct" DESC) AS rn
    FROM avg_order_growth
),

/* -------- average MONTH-OVER-MONTH % growth in REVENUE ------------- */
revenue_growth AS (
    SELECT
        m."category",
        ("revenue" - LAG("revenue") OVER (PARTITION BY m."category" ORDER BY m."month"))
        / NULLIF(LAG("revenue") OVER (PARTITION BY m."category" ORDER BY m."month"), 0) * 100
        AS "pct_revenue_growth"
    FROM monthly_metrics m
    JOIN top_cat t
          ON m."category" = t."category"      -- only keep the winning category
         AND t.rn = 1
),
avg_revenue_growth AS (
    SELECT
        "category",
        AVG("pct_revenue_growth") AS "avg_monthly_revenue_growth_pct"
    FROM revenue_growth
    WHERE "pct_revenue_growth" IS NOT NULL
    GROUP BY "category"
)

/* ---------------------------  FINAL OUTPUT  ------------------------ */
SELECT
    t."category",
    ROUND(t."avg_monthly_order_growth_pct", 2)   AS "avg_monthly_order_growth_pct",
    ROUND(r."avg_monthly_revenue_growth_pct", 2) AS "avg_monthly_revenue_growth_pct"
FROM top_cat            t
JOIN avg_revenue_growth  r
      ON t."category" = r."category"
WHERE t.rn = 1;