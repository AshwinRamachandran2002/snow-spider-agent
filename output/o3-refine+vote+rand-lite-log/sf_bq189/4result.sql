/*-------------------------------------------------------------------
  1. Pull all completed order–item rows and attach the product category
  2. Build month‑level aggregates (distinct order count & revenue)
  3. Calculate month‑to‑month % growth for orders and revenue
  4. Find the category with the highest average order‑growth %
  5. For that category, return its average order‑growth % and
     average revenue‑growth %
-------------------------------------------------------------------*/
WITH completed_items AS (       -- step 1
    SELECT
        oi."order_id",
        oi."sale_price",
        oi."created_at",
        p."category"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"   oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"      p
          ON oi."product_id" = p."id"
    WHERE oi."status" = 'Complete'
),
monthly_category AS (           -- step 2
    SELECT
        "category",
        DATE_TRUNC('month', TO_TIMESTAMP_NTZ("created_at" / 1000000))  AS order_month,
        COUNT(DISTINCT "order_id")                                    AS unique_orders,
        SUM("sale_price")                                             AS revenue
    FROM completed_items
    GROUP BY "category", order_month
),
monthly_growth AS (             -- step 3
    SELECT
        "category",
        order_month,
        unique_orders,
        revenue,
        LAG(unique_orders) OVER (PARTITION BY "category" ORDER BY order_month)  AS prev_orders,
        LAG(revenue)       OVER (PARTITION BY "category" ORDER BY order_month)  AS prev_revenue
    FROM monthly_category
),
percent_growth AS (
    SELECT
        "category",
        order_month,
        CASE WHEN prev_orders  > 0 THEN (unique_orders - prev_orders)  * 100.0 / prev_orders  END AS orders_growth_pct,
        CASE WHEN prev_revenue > 0 THEN (revenue       - prev_revenue) * 100.0 / prev_revenue END AS revenue_growth_pct
    FROM monthly_growth
),
avg_growth AS (                 -- average order‑growth % per category
    SELECT
        "category",
        AVG(orders_growth_pct) AS avg_orders_growth_pct
    FROM percent_growth
    GROUP BY "category"
),
top_category AS (               -- step 4
    SELECT
        "category",
        avg_orders_growth_pct
    FROM avg_growth
    ORDER BY avg_orders_growth_pct DESC NULLS LAST, "category"
    LIMIT 1
),
final_revenue_growth AS (       -- step 5
    SELECT
        t."category",
        t.avg_orders_growth_pct,
        AVG(p.revenue_growth_pct) AS avg_revenue_growth_pct
    FROM top_category   t
    JOIN percent_growth p  ON p."category" = t."category"
    GROUP BY t."category", t.avg_orders_growth_pct
)
SELECT
    "category",
    ROUND(avg_orders_growth_pct , 4) AS avg_monthly_order_growth_pct,
    ROUND(avg_revenue_growth_pct, 4) AS avg_monthly_revenue_growth_pct
FROM final_revenue_growth;