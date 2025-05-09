/* -------------------------------------------------------------
   1)  Work only with completed order-items and attach product
       category information plus month derived from micro-epoch.
----------------------------------------------------------------*/
WITH completed_order_items AS (            -- step-1: filter to “Complete” items
    SELECT
        oi."order_id",
        oi."product_id",
        oi."created_at",
        oi."sale_price"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS" oi
    WHERE oi."status" = 'Complete'
),
orders_with_category AS (                  -- step-2: add category & month
    SELECT
        p."category",
        DATE_TRUNC('month',
                   TO_TIMESTAMP_LTZ(coi."created_at" / 1000000))  AS "order_month",
        coi."order_id",
        coi."sale_price"
    FROM completed_order_items                coi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"  p
      ON coi."product_id" = p."id"
),
/* -------------------------------------------------------------
   2)  Aggregate by category & month to get unique order-counts
       and revenue.
----------------------------------------------------------------*/
monthly_metrics AS (
    SELECT
        "category",
        "order_month",
        COUNT(DISTINCT "order_id") AS "unique_orders",
        SUM("sale_price")          AS "revenue"
    FROM orders_with_category
    GROUP BY
        "category",
        "order_month"
),
/* -------------------------------------------------------------
   3)  Month-to-month % growth in unique orders per category.
----------------------------------------------------------------*/
order_growth AS (
    SELECT
        "category",
        "order_month",
        "unique_orders",
        LAG("unique_orders")
            OVER (PARTITION BY "category" ORDER BY "order_month") AS "prev_unique_orders",
        ( "unique_orders"
          - LAG("unique_orders") OVER (PARTITION BY "category" ORDER BY "order_month") )
          / NULLIF( LAG("unique_orders") OVER (PARTITION BY "category" ORDER BY "order_month"), 0 )
          AS "pct_order_growth"
    FROM monthly_metrics
),
avg_order_growth AS (                      -- average monthly order-growth
    SELECT
        "category",
        AVG("pct_order_growth") AS "avg_monthly_order_growth"
    FROM order_growth
    WHERE "pct_order_growth" IS NOT NULL
    GROUP BY "category"
),
/* -------------------------------------------------------------
   4)  Identify the single category with the highest average
       order-growth rate.
----------------------------------------------------------------*/
best_category AS (
    SELECT "category"
    FROM   avg_order_growth
    ORDER  BY "avg_monthly_order_growth" DESC NULLS LAST
    LIMIT  1
),
/* -------------------------------------------------------------
   5)  Month-to-month % revenue growth for every category.
----------------------------------------------------------------*/
revenue_growth AS (
    SELECT
        "category",
        "order_month",
        "revenue",
        LAG("revenue")
            OVER (PARTITION BY "category" ORDER BY "order_month") AS "prev_revenue",
        ( "revenue"
          - LAG("revenue") OVER (PARTITION BY "category" ORDER BY "order_month") )
          / NULLIF( LAG("revenue") OVER (PARTITION BY "category" ORDER BY "order_month"), 0 )
          AS "pct_revenue_growth"
    FROM monthly_metrics
),
avg_revenue_growth AS (                    -- average monthly revenue-growth
    SELECT
        "category",
        AVG("pct_revenue_growth") AS "avg_monthly_revenue_growth"
    FROM revenue_growth
    WHERE "pct_revenue_growth" IS NOT NULL
    GROUP BY "category"
)
/* -------------------------------------------------------------
   6)  Final answer: category with highest avg order-growth and
       its corresponding average revenue-growth.
----------------------------------------------------------------*/
SELECT
    bc."category",
    aog."avg_monthly_order_growth",
    arg."avg_monthly_revenue_growth"
FROM best_category      bc
JOIN avg_order_growth   aog  ON bc."category" = aog."category"
JOIN avg_revenue_growth arg  ON bc."category" = arg."category";