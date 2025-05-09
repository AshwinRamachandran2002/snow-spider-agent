WITH order_lines AS (
    SELECT
        o."order_id",
        TO_CHAR(TO_TIMESTAMP(o."created_at"/1e6),'YYYY-MM') AS "yr_mo",
        p."category",
        oi."sale_price"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"       o
      ON o."order_id" = oi."order_id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"     p
      ON p."id" = oi."product_id"
    WHERE o."status" = 'Complete'
), monthly_orders AS (
    SELECT
        "category",
        "yr_mo",
        COUNT(DISTINCT "order_id") AS "unique_orders"
    FROM order_lines
    GROUP BY "category","yr_mo"
), orders_growth AS (
    SELECT
        "category",
        "yr_mo",
        "unique_orders",
        LAG("unique_orders") OVER (PARTITION BY "category" ORDER BY "yr_mo") AS "prev_orders"
    FROM monthly_orders
), avg_order_growth AS (
    SELECT
        "category",
        AVG( ( "unique_orders" - "prev_orders") / NULLIF("prev_orders",0) * 100 ) 
            AS "avg_mo_order_growth_pct"
    FROM orders_growth
    WHERE "prev_orders" IS NOT NULL
    GROUP BY "category"
), top_category AS (
    SELECT "category","avg_mo_order_growth_pct"
    FROM (
        SELECT 
            "category",
            "avg_mo_order_growth_pct",
            ROW_NUMBER() OVER (ORDER BY "avg_mo_order_growth_pct" DESC) AS rn
        FROM avg_order_growth
    ) WHERE rn = 1
), monthly_revenue AS (
    SELECT
        ol."yr_mo",
        SUM(ol."sale_price") AS "revenue"
    FROM order_lines ol
    JOIN top_category tc
      ON ol."category" = tc."category"
    GROUP BY ol."yr_mo"
), revenue_growth AS (
    SELECT
        "yr_mo",
        "revenue",
        LAG("revenue") OVER (ORDER BY "yr_mo") AS "prev_revenue"
    FROM monthly_revenue
), avg_revenue_growth AS (
    SELECT
        AVG( ( "revenue" - "prev_revenue") / NULLIF("prev_revenue",0) * 100 ) 
            AS "avg_mo_revenue_growth_pct"
    FROM revenue_growth
    WHERE "prev_revenue" IS NOT NULL
)
SELECT
    tc."category"                                       AS "top_growth_category",
    ROUND(tc."avg_mo_order_growth_pct",4)    AS "avg_mo_order_growth_pct",
    ROUND(arg."avg_mo_revenue_growth_pct",4) AS "avg_mo_revenue_growth_pct"
FROM top_category tc
CROSS JOIN avg_revenue_growth arg;