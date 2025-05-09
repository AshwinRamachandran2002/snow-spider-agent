/* 1.  Pick only completed order‑items, convert micro‑second epoch to month */
WITH completed_items AS (   
        SELECT  oi."order_id",
                oi."product_id",
                oi."sale_price",
                DATE_TRUNC( 'month'
                           , TO_TIMESTAMP( oi."created_at" / 1000000 ) )      AS month
        FROM   "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS"  oi
        WHERE  oi."status" = 'Complete'
),

/* 2.  Attach product category */
items_with_category AS (  
        SELECT  ci."order_id",
                ci."sale_price",
                ci.month,
                p."category"
        FROM   completed_items ci
        JOIN   "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."PRODUCTS"  p
               ON  ci."product_id" = p."id"
),

/* 3.  Monthly metrics (orders & revenue) per category */
monthly_category_metrics AS (
        SELECT  "category",
                month,
                COUNT(DISTINCT "order_id")         AS orders_cnt,
                SUM("sale_price")                  AS revenue
        FROM    items_with_category
        GROUP BY "category", month
),

/* 4.  Add previous‑month values to compute growth rates */
metrics_with_lag AS (
        SELECT  m.*,
                LAG(orders_cnt) OVER (PARTITION BY "category" ORDER BY month)  AS prev_orders_cnt,
                LAG(revenue)    OVER (PARTITION BY "category" ORDER BY month)  AS prev_revenue
        FROM    monthly_category_metrics m
),

/* 5.  Month‑over‑month growth (%) */
growth_rates AS (  
        SELECT  "category",
                month,
                /* percentage growth in order count */
                CASE WHEN prev_orders_cnt > 0
                     THEN (orders_cnt - prev_orders_cnt) * 100.0 / prev_orders_cnt
                END                                           AS orders_growth_pct,
                /* percentage growth in revenue */
                CASE WHEN prev_revenue > 0
                     THEN (revenue - prev_revenue) * 100.0 / prev_revenue
                END                                           AS revenue_growth_pct
        FROM    metrics_with_lag
),

/* 6.  Average monthly order‑growth per category */
avg_order_growth AS (  
        SELECT  "category",
                AVG(orders_growth_pct)   AS avg_orders_growth_pct
        FROM    growth_rates
        WHERE   orders_growth_pct IS NOT NULL
        GROUP BY "category"
),

/* 7.  Category with the highest average order‑growth */
top_category AS (  
        SELECT  "category"
        FROM    avg_order_growth
        ORDER BY avg_orders_growth_pct DESC NULLS LAST
        LIMIT 1
),

/* 8.  For that category, compute average monthly revenue‑growth */
result AS (  
        SELECT  g."category",
                a.avg_orders_growth_pct,
                AVG(g.revenue_growth_pct)    AS avg_revenue_growth_pct
        FROM    growth_rates            g
        JOIN    top_category            t  ON g."category" = t."category"
        JOIN    avg_order_growth        a  ON g."category" = a."category"
        WHERE   g.revenue_growth_pct IS NOT NULL
        GROUP BY g."category", a.avg_orders_growth_pct
)

SELECT  "category"                                      AS product_category_with_max_order_growth,
        ROUND(avg_orders_growth_pct , 4)                AS avg_monthly_order_growth_pct,
        ROUND(avg_revenue_growth_pct, 4)                AS avg_monthly_revenue_growth_pct
FROM    result;