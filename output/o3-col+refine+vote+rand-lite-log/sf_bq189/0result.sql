/* ------------------------------------------------------------
   1.  Aggregate completed order-items to month level per category
   2.  Compute MoM % change in unique-orders and revenue
   3.  Average the order growth % for every category and pick
       the one with the highest average
   4.  For that top category, average its monthly revenue growth %
-----------------------------------------------------------------*/
WITH monthly AS (   -- step-1
    SELECT
        p."category",
        TO_CHAR( TO_TIMESTAMP_NTZ( oi."created_at" / 1000000 ), 'YYYY-MM' )  AS "year_month",
        COUNT(DISTINCT oi."order_id")                                        AS "unique_orders",
        SUM(oi."sale_price")                                                 AS "monthly_revenue"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"     p
          ON oi."product_id" = p."id"
    WHERE oi."status" = 'Complete'
    GROUP BY p."category",
             TO_CHAR( TO_TIMESTAMP_NTZ( oi."created_at" / 1000000 ), 'YYYY-MM')
), deltas AS (      -- step-2
    SELECT
        m.*,
        100.0 * ( m."unique_orders"
                  - LAG(m."unique_orders")  OVER(PARTITION BY m."category" ORDER BY m."year_month") )
              / NULLIF( LAG(m."unique_orders") OVER(PARTITION BY m."category" ORDER BY m."year_month"), 0 )
              AS "pct_growth_orders",
        100.0 * ( m."monthly_revenue"
                  - LAG(m."monthly_revenue") OVER(PARTITION BY m."category" ORDER BY m."year_month") )
              / NULLIF( LAG(m."monthly_revenue") OVER(PARTITION BY m."category" ORDER BY m."year_month"), 0 )
              AS "pct_growth_revenue"
    FROM monthly m
), order_growth AS ( -- step-3
    SELECT
        "category",
        AVG("pct_growth_orders") AS "avg_monthly_order_growth_pct"
    FROM deltas
    GROUP BY "category"
), top_cat AS (
    SELECT
        "category",
        "avg_monthly_order_growth_pct"
    FROM order_growth
    ORDER BY "avg_monthly_order_growth_pct" DESC NULLS LAST
    LIMIT 1
), revenue_growth AS (  -- step-4
    SELECT
        AVG(d."pct_growth_revenue") AS "avg_monthly_revenue_growth_pct"
    FROM deltas d
    JOIN top_cat t
      ON d."category" = t."category"
)
SELECT
    t."category",
    ROUND(t."avg_monthly_order_growth_pct", 4)   AS "avg_monthly_order_growth_pct",
    ROUND(r."avg_monthly_revenue_growth_pct",4)  AS "avg_monthly_revenue_growth_pct"
FROM top_cat        t
CROSS JOIN revenue_growth r;