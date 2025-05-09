/* -----------------------------------------------------------
   1) Work only with COMPLETE order-items joined to PRODUCTS.
   2) For every category, count DISTINCT orders per month.
   3) Compute month-over-month % growth in those counts and
      average the growth per category.
   4) Keep the category with the highest average order-growth.
   5) For that category, aggregate revenue by month,
      compute its month-over-month % growth and
      take the average of those revenue-growth rates.
   6) Return the category together with both averages.
------------------------------------------------------------*/
WITH complete_items AS (      -- all COMPLETE sales with month stamp
    SELECT  p."category"                                              AS "product_category",
            oi."order_id",
            oi."sale_price",
            DATE_TRUNC('month',
                       TO_TIMESTAMP_NTZ(oi."created_at" / 1000000))   AS "order_month"
    FROM  THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  oi
    JOIN  THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"     p
          ON oi."product_id" = p."id"
    WHERE oi."status" = 'Complete'
),
/* ---- count distinct orders per month & category ------------- */
monthly_orders AS (
    SELECT  "product_category",
            "order_month",
            COUNT(DISTINCT "order_id")       AS "unique_orders"
    FROM    complete_items
    GROUP BY 1,2
),
/* ---- month-over-month % growth in unique orders -------------- */
order_growth AS (
    SELECT  mo.*,
            LAG("unique_orders") OVER (PARTITION BY "product_category"
                                       ORDER BY "order_month")        AS "prev_orders",
            (("unique_orders"
              - LAG("unique_orders") OVER (PARTITION BY "product_category"
                                           ORDER BY "order_month"))
              / NULLIF(LAG("unique_orders") OVER (PARTITION BY "product_category"
                                                  ORDER BY "order_month"),0) ) * 100
                                                                       AS "pct_growth_orders"
    FROM    monthly_orders mo
),
/* ---- average monthly order-growth per category --------------- */
avg_order_growth AS (
    SELECT  "product_category",
            AVG("pct_growth_orders")         AS "avg_mthly_order_growth_pct"
    FROM    order_growth
    GROUP BY 1
),
/* ---- category with highest avg order growth ------------------ */
top_cat AS (
    SELECT  "product_category",
            "avg_mthly_order_growth_pct"
    FROM    avg_order_growth
    QUALIFY ROW_NUMBER() OVER (ORDER BY "avg_mthly_order_growth_pct" DESC NULLS LAST) = 1
),
/* ---- monthly revenue for the top-growth category ------------- */
monthly_revenue AS (
    SELECT  ci."product_category",
            ci."order_month",
            SUM(ci."sale_price")             AS "revenue"
    FROM    complete_items  ci
    JOIN    top_cat         tc
           ON ci."product_category" = tc."product_category"
    GROUP BY 1,2
),
/* ---- month-over-month % revenue growth ----------------------- */
revenue_growth AS (
    SELECT  mr.*,
            LAG("revenue") OVER (ORDER BY "order_month")              AS "prev_revenue",
            (("revenue"
              - LAG("revenue") OVER (ORDER BY "order_month"))
              / NULLIF(LAG("revenue") OVER (ORDER BY "order_month"),0) ) * 100
                                                                       AS "pct_growth_revenue"
    FROM    monthly_revenue mr
),
/* ---- average monthly revenue-growth for that category -------- */
avg_revenue_growth AS (
    SELECT  AVG("pct_growth_revenue")        AS "avg_mthly_revenue_growth_pct"
    FROM    revenue_growth
)

/* ---- final result ------------------------------------------- */
SELECT  tc."product_category",
        tc."avg_mthly_order_growth_pct",
        arg."avg_mthly_revenue_growth_pct"
FROM    top_cat            tc
CROSS JOIN avg_revenue_growth  arg;