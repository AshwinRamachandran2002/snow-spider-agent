WITH completed_items AS (   -- all completed order-item rows with calendar month and category  
    SELECT 
        oi."order_id",
        p."category"                                     AS "product_category",
        oi."sale_price",
        TO_CHAR(TO_TIMESTAMP_LTZ(oi."created_at"/1000000),'YYYY-MM')  AS "year_month"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"     p
          ON oi."product_id" = p."id"
    WHERE oi."status" = 'Complete'
), 
  
/* ---------- 1.  Monthly distinct-order counts per category ---------- */
monthly_orders AS (
    SELECT  
        "product_category",
        "year_month",
        COUNT(DISTINCT "order_id")                       AS "unique_orders"
    FROM completed_items
    GROUP BY "product_category","year_month"
), 
  
/* ---------- 2.  Month-over-month % growth in orders ---------- */
order_growth AS (
    SELECT
        "product_category",
        "year_month",
        ("unique_orders"
         - LAG("unique_orders") OVER (PARTITION BY "product_category" ORDER BY "year_month"))
        / NULLIF(LAG("unique_orders") OVER (PARTITION BY "product_category" ORDER BY "year_month"),0)
        * 100                                             AS "pct_growth_orders"
    FROM monthly_orders
), 
  
/* ---------- 3.  Average MoM order-growth % for every category ---------- */
avg_order_growth AS (
    SELECT
        "product_category",
        ROUND(AVG("pct_growth_orders"),2)                AS "avg_monthly_order_growth_pct"
    FROM order_growth
    WHERE "pct_growth_orders" IS NOT NULL
    GROUP BY "product_category"
), 
  
/* ---------- 4.  Pick the leader (highest avg order growth) ---------- */
top_category AS (
    SELECT 
        "product_category",
        "avg_monthly_order_growth_pct"
    FROM   avg_order_growth
    ORDER  BY "avg_monthly_order_growth_pct" DESC NULLS LAST
    LIMIT 1
), 
  
/* ---------- 5.  Monthly revenue for that winning category ---------- */
monthly_revenue AS (
    SELECT
        ci."product_category",
        ci."year_month",
        SUM(ci."sale_price")                            AS "monthly_revenue"
    FROM completed_items  ci
    JOIN top_category      tc  
          ON ci."product_category" = tc."product_category"
    GROUP BY ci."product_category", ci."year_month"
), 
  
/* ---------- 6.  MoM % revenue growth ---------- */
revenue_growth AS (
    SELECT
        "product_category",
        "year_month",
        ("monthly_revenue"
         - LAG("monthly_revenue") OVER (ORDER BY "year_month"))
        / NULLIF(LAG("monthly_revenue") OVER (ORDER BY "year_month"),0)
        * 100                                            AS "pct_growth_revenue"
    FROM monthly_revenue
), 
  
/* ---------- 7.  Average MoM revenue-growth % for the winning category ---------- */
avg_revenue_growth AS (
    SELECT
        "product_category",
        ROUND(AVG("pct_growth_revenue"),2)              AS "avg_monthly_revenue_growth_pct"
    FROM revenue_growth
    WHERE "pct_growth_revenue" IS NOT NULL
    GROUP BY "product_category"
)
  
/* ---------- 8.  Final answer ---------- */
SELECT
    tc."product_category",
    tc."avg_monthly_order_growth_pct",
    arg."avg_monthly_revenue_growth_pct"
FROM top_category       tc
JOIN avg_revenue_growth arg
      ON tc."product_category" = arg."product_category";