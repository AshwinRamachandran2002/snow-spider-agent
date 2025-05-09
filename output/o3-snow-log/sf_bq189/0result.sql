/*-----------------------------------------------------------
  1) Aggregate completed order-items to the month/category level
     – unique order count and total revenue per month.
  2) For every category, derive month-over-month % change
     in both order count and revenue by using LAG().
  3) Average the monthly order-growth % for each category and
     pick the category with the highest average.
  4) For that top category, calculate the average monthly
     revenue-growth %.
-----------------------------------------------------------*/
WITH monthly AS (     -- step-1
    SELECT
        TO_CHAR(TO_TIMESTAMP_NTZ(oi."created_at"/1000000),'YYYY-MM')   AS "yr_mo",
        p."category"                                                  AS "category",
        COUNT(DISTINCT oi."order_id")                                 AS "unique_orders",
        SUM(oi."sale_price")                                          AS "revenue"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"      p
          ON oi."product_id" = p."id"
    WHERE oi."status" = 'Complete'
    GROUP BY "yr_mo", p."category"
),

monthly_with_lag AS ( -- step-2
    SELECT
        m."category",
        m."yr_mo",
        m."unique_orders",
        m."revenue",
        LAG(m."unique_orders") OVER (PARTITION BY m."category"
                                     ORDER BY TO_DATE(m."yr_mo"||'-01')) AS "prev_orders",
        LAG(m."revenue")       OVER (PARTITION BY m."category"
                                     ORDER BY TO_DATE(m."yr_mo"||'-01')) AS "prev_revenue"
    FROM monthly m
),

growths AS (          -- calculate MoM % growth
    SELECT
        "category",
        "yr_mo",
        "unique_orders",
        "revenue",
        CASE
            WHEN "prev_orders" IS NOT NULL AND "prev_orders" <> 0
            THEN (("unique_orders" - "prev_orders") * 100.0)
                 / NULLIF("prev_orders",0)
        END AS "order_growth_pct",
        CASE
            WHEN "prev_revenue" IS NOT NULL AND "prev_revenue" <> 0
            THEN (("revenue" - "prev_revenue") * 100.0)
                 / NULLIF("prev_revenue",0)
        END AS "revenue_growth_pct"
    FROM monthly_with_lag
),

category_order_avg AS (  -- step-3
    SELECT
        "category",
        AVG("order_growth_pct") AS "avg_order_growth_pct"
    FROM growths
    GROUP BY "category"
),

top_category AS (       -- fetch the category with max avg order-growth
    SELECT
        "category",
        "avg_order_growth_pct"
    FROM category_order_avg
    ORDER BY "avg_order_growth_pct" DESC NULLS LAST
    LIMIT 1
)

-- step-4 : final answer
SELECT
    t."category",
    ROUND(t."avg_order_growth_pct", 4)            AS "avg_monthly_order_growth_pct",
    ROUND(
        (SELECT AVG("revenue_growth_pct")
         FROM growths g
         WHERE g."category" = t."category"), 4)   AS "avg_monthly_revenue_growth_pct"
FROM top_category t;