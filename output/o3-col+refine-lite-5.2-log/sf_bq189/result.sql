/* ---------------------------------------------------------
   1)  Build monthly DISTINCT‑order counts per product category
   2)  Turn those counts into month‑over‑month %‑changes,
       then average them → “avg_monthly_order_growth”.
   3)  Pick the category whose average growth is highest.
   4)  For that one category, build monthly revenue totals,
       convert them to %‑changes, and average →
       “avg_monthly_revenue_growth”.
   5)  Return the single winning category with both metrics.
----------------------------------------------------------*/
WITH monthly_orders AS (      --‑‑ # distinct orders per category / month
    SELECT
        p."category"                                           AS "CATEGORY",
        DATE_TRUNC('month', TO_TIMESTAMP(oi."created_at"/1e6)) AS "ORDER_MONTH",
        COUNT(DISTINCT oi."order_id")                          AS "ORDERS_IN_MONTH"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS" oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"   p
      ON oi."product_id" = p."id"
    WHERE oi."status" = 'Complete'
    GROUP BY p."category",
             DATE_TRUNC('month', TO_TIMESTAMP(oi."created_at"/1e6))
),
order_growth AS (           --‑‑ month‑over‑month % change in order counts
    SELECT
        "CATEGORY",
        "ORDER_MONTH",
        ( "ORDERS_IN_MONTH"
          - LAG("ORDERS_IN_MONTH")
                OVER (PARTITION BY "CATEGORY" ORDER BY "ORDER_MONTH") )
        / NULLIF(
            LAG("ORDERS_IN_MONTH")
                OVER (PARTITION BY "CATEGORY" ORDER BY "ORDER_MONTH"), 0
          )                                                    AS "PCT_CHANGE"
    FROM monthly_orders
),
order_growth_avg AS (       --‑‑ average of those % changes by category
    SELECT
        "CATEGORY",
        AVG("PCT_CHANGE") AS "AVG_MONTHLY_ORDER_GROWTH"
    FROM order_growth
    WHERE "PCT_CHANGE" IS NOT NULL
    GROUP BY "CATEGORY"
),
top_category AS (           --‑‑ single category with the highest order‑growth
    SELECT *
    FROM order_growth_avg
    ORDER BY "AVG_MONTHLY_ORDER_GROWTH" DESC
    LIMIT 1
),
monthly_revenue AS (        --‑‑ revenue per month for that category
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP(oi."created_at"/1e6)) AS "ORDER_MONTH",
        SUM(oi."sale_price")                                   AS "REVENUE_IN_MONTH"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS" oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"   p
      ON oi."product_id" = p."id"
    WHERE oi."status" = 'Complete'
      AND p."category" = (SELECT "CATEGORY" FROM top_category)
    GROUP BY DATE_TRUNC('month', TO_TIMESTAMP(oi."created_at"/1e6))
),
revenue_growth AS (         --‑‑ month‑over‑month % change in revenue
    SELECT
        "ORDER_MONTH",
        ( "REVENUE_IN_MONTH"
          - LAG("REVENUE_IN_MONTH") OVER (ORDER BY "ORDER_MONTH") )
        / NULLIF( LAG("REVENUE_IN_MONTH") OVER (ORDER BY "ORDER_MONTH"), 0 )
                                                                AS "PCT_CHANGE"
    FROM monthly_revenue
),
avg_revenue_growth AS (     --‑‑ average % revenue growth for the category
    SELECT
        AVG("PCT_CHANGE") AS "AVG_MONTHLY_REVENUE_GROWTH"
    FROM revenue_growth
    WHERE "PCT_CHANGE" IS NOT NULL
)
SELECT
    tc."CATEGORY"                       AS "TOP_GROWTH_CATEGORY",
    ROUND(tc."AVG_MONTHLY_ORDER_GROWTH",4)   AS "AVG_MONTHLY_ORDER_GROWTH",
    ROUND(arg."AVG_MONTHLY_REVENUE_GROWTH",4) AS "AVG_MONTHLY_REVENUE_GROWTH"
FROM top_category        tc
CROSS JOIN avg_revenue_growth arg;