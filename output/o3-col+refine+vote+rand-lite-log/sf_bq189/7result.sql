/* -----------------------------------------------------------
   1.  Build monthly order-count & revenue per product category
   2.  Compute month-over-month (MoM) % growth for both metrics
   3.  Average the MoM order-count growth for every category
   4.  Pick the category with the highest average MoM order growth
   5.  For that category, calculate the average MoM revenue growth
   6.  Return the winning category together with both averages
   ----------------------------------------------------------- */
WITH monthly_stats AS (                 -- step-1
    SELECT DATE_TRUNC(
               'month',
               TO_TIMESTAMP_NTZ(oi."created_at" / 1000000)
           )                                 AS "month",
           p."category"                      AS "category",
           COUNT(DISTINCT oi."order_id")     AS "num_orders",
           SUM(oi."sale_price")              AS "revenue"
    FROM   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  oi
    JOIN   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"     p
           ON oi."product_id" = p."id"
    WHERE  oi."status" = 'Complete'
    GROUP  BY "month", p."category"
),
lagged AS (                               -- step-2
    SELECT  "month",
            "category",
            "num_orders",
            "revenue",
            LAG("num_orders") OVER (PARTITION BY "category"
                                     ORDER BY "month")        AS "prev_orders",
            LAG("revenue")    OVER (PARTITION BY "category"
                                     ORDER BY "month")        AS "prev_revenue"
    FROM   monthly_stats
),
pct_growth AS (                           -- still step-2
    SELECT  "category",
            "month",
            100.0 * ("num_orders" - "prev_orders")
                   / NULLIF("prev_orders", 0)                 AS "pct_order_growth",
            100.0 * ("revenue"    - "prev_revenue")
                   / NULLIF("prev_revenue", 0)                AS "pct_revenue_growth"
    FROM    lagged
    WHERE   "prev_orders"  IS NOT NULL      -- skip first month per category
),
avg_order_growth AS (                     -- step-3
    SELECT  "category",
            AVG("pct_order_growth")        AS "avg_pct_order_growth"
    FROM    pct_growth
    GROUP   BY "category"
),
top_category AS (                         -- step-4
    SELECT  "category",
            "avg_pct_order_growth"
    FROM    avg_order_growth
    ORDER BY "avg_pct_order_growth" DESC NULLS LAST
    LIMIT 1
),
avg_revenue_growth AS (                   -- step-5
    SELECT  "category",
            AVG("pct_revenue_growth")      AS "avg_pct_revenue_growth"
    FROM    pct_growth
    WHERE   "category" IN (SELECT "category" FROM top_category)
    GROUP   BY "category"
)
-- step-6 : final answer
SELECT  t."category",
        ROUND(t."avg_pct_order_growth",   4) AS "avg_monthly_order_growth_pct",
        ROUND(r."avg_pct_revenue_growth", 4) AS "avg_monthly_revenue_growth_pct"
FROM    top_category        t
JOIN    avg_revenue_growth  r
       ON t."category" = r."category";