/*------------------------------------------------------------
  1)  Work out the average month-to-month order-growth %
      for every product category (completed orders only)
  2)  Pick the category with the highest average from step-1
  3)  For that winning category, compute the average month-to-month
      revenue-growth %
------------------------------------------------------------*/
WITH monthly_orders AS (        /* unique-order count per month & category */
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP(oi."created_at" / 1000000)) AS "month",
        p."category",
        COUNT(DISTINCT oi."order_id")                                AS "orders"
    FROM   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  oi
    JOIN   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"      p
           ON p."id" = oi."product_id"
    WHERE  oi."status" = 'Complete'
    GROUP  BY 1, 2
),
order_growth AS (               /* month-to-month % growth in order count */
    SELECT
        "category",
        "month",
        "orders",
        ( "orders"
          / NULLIF( LAG("orders") OVER (PARTITION BY "category" ORDER BY "month"), 0 ) - 1
        ) * 100                                                     AS "order_growth_pct"
    FROM   monthly_orders
),
avg_order_growth AS (           /* average of those growth %’s per category */
    SELECT
        "category",
        AVG("order_growth_pct") AS "avg_order_growth_pct"
    FROM   order_growth
    GROUP  BY "category"
),
top_category AS (               /* single best category by that metric */
    SELECT  "category"
    FROM    avg_order_growth
    ORDER BY "avg_order_growth_pct" DESC NULLS LAST
    LIMIT   1
),
monthly_revenue AS (            /* month-level revenue for the top category */
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP(oi."created_at" / 1000000)) AS "month",
        SUM(oi."sale_price")                                         AS "revenue"
    FROM   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  oi
    JOIN   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"      p
           ON p."id" = oi."product_id"
    JOIN   top_category tc
           ON p."category" = tc."category"
    WHERE  oi."status" = 'Complete'
    GROUP  BY 1
),
revenue_growth AS (             /* month-to-month % growth in that revenue */
    SELECT
        "month",
        "revenue",
        ( "revenue"
          / NULLIF( LAG("revenue") OVER (ORDER BY "month"), 0 ) - 1
        ) * 100                                                     AS "revenue_growth_pct"
    FROM   monthly_revenue
),
avg_revenue_growth AS (         /* average of those revenue growth %’s */
    SELECT
        AVG("revenue_growth_pct") AS "avg_revenue_growth_pct"
    FROM   revenue_growth
)
SELECT
    tc."category",
    ROUND(aog."avg_order_growth_pct", 4)   AS "avg_monthly_order_growth_pct",
    ROUND(arg."avg_revenue_growth_pct", 4) AS "avg_monthly_revenue_growth_pct"
FROM       top_category        tc
JOIN       avg_order_growth    aog  ON aog."category" = tc."category"
CROSS JOIN avg_revenue_growth  arg;