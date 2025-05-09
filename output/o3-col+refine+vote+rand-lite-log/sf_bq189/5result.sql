/* ---------------------------------------------------------------
   1. Determine the category with the highest average MoM growth
      in UNIQUE ORDER COUNT (completed orders only)
   2. For that winning category, calculate the average MoM
      REVENUE growth rate.
---------------------------------------------------------------- */
WITH completed_items AS (      -- finished line-items only
    SELECT
        oi."order_id",
        oi."product_id",
        oi."sale_price",
        oi."created_at"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS" oi
    WHERE oi."status" = 'Complete'
),

/* --------  Unique-order count per category per month ---------- */
monthly_orders AS (
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP(ci."created_at" / 1e6)) AS "order_month",
        p."category",
        COUNT(DISTINCT ci."order_id")                            AS "unique_orders"
    FROM completed_items                 ci
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS" p
      ON p."id" = ci."product_id"
    GROUP BY 1, 2
),

/* ------  Month-over-month % growth in unique-order count ------ */
order_growth AS (
    SELECT
        "category",
        "order_month",
        "unique_orders",
        LAG("unique_orders") OVER (PARTITION BY "category" ORDER BY "order_month") AS "prev_orders",
        (
          ("unique_orders" - LAG("unique_orders") OVER (PARTITION BY "category" ORDER BY "order_month"))
          / NULLIF(LAG("unique_orders") OVER (PARTITION BY "category" ORDER BY "order_month"), 0)
        ) * 100 AS "pct_order_growth"
    FROM monthly_orders
),

/* ----------  Average MoM order-growth per category ----------- */
avg_order_growth AS (
    SELECT
        "category",
        AVG("pct_order_growth") AS "avg_monthly_order_growth_pct"
    FROM order_growth
    WHERE "pct_order_growth" IS NOT NULL
    GROUP BY "category"
),

/* -----------  Pick the category with the highest avg ---------- */
top_category AS (
    SELECT
        "category",
        "avg_monthly_order_growth_pct"
    FROM avg_order_growth
    QUALIFY RANK() OVER (ORDER BY "avg_monthly_order_growth_pct" DESC) = 1
),

/* --------------  Monthly revenue for that category ------------ */
monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP(ci."created_at" / 1e6)) AS "order_month",
        p."category",
        SUM(ci."sale_price")                                     AS "revenue"
    FROM completed_items                 ci
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS" p
      ON p."id" = ci."product_id"
    JOIN top_category tc
      ON p."category" = tc."category"
    GROUP BY 1, 2
),

/* --------  MoM % growth in revenue for the top category ------- */
revenue_growth AS (
    SELECT
        "order_month",
        "revenue",
        LAG("revenue") OVER (ORDER BY "order_month") AS "prev_revenue",
        (
          ("revenue" - LAG("revenue") OVER (ORDER BY "order_month"))
          / NULLIF(LAG("revenue") OVER (ORDER BY "order_month"), 0)
        ) * 100 AS "pct_revenue_growth"
    FROM monthly_revenue
)

/* --------------------  Final combined result ------------------ */
SELECT
    tc."category",
    tc."avg_monthly_order_growth_pct",
    AVG(rg."pct_revenue_growth") AS "avg_monthly_revenue_growth_pct"
FROM top_category    tc
LEFT JOIN revenue_growth rg
       ON 1 = 1         -- cartesian join to pull all rows
WHERE rg."pct_revenue_growth" IS NOT NULL
GROUP BY
    tc."category",
    tc."avg_monthly_order_growth_pct";