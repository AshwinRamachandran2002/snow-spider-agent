WITH delivered_orders AS (
    /* 1.  All line‑items in orders that were completed and delivered
           before 2022‑01‑01, with their delivery month, category,
           sale price and unit cost                                           */
    SELECT
        oi."order_id",
        oi."sale_price",
        p."category"                                                        AS product_category,
        p."cost"                                                            AS product_cost,
        DATE_TRUNC('month', TO_TIMESTAMP( o."delivered_at" / 1e6 ))         AS month_start
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS  oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS       o
          ON oi."order_id" = o."order_id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.PRODUCTS     p
          ON oi."product_id" = p."id"
    WHERE o."status" = 'Complete'
      AND o."delivered_at" IS NOT NULL
      AND TO_TIMESTAMP( o."delivered_at" / 1e6 ) < '2022-01-01'::TIMESTAMP
),
agg AS (
    /* 2.  Monthly aggregation by product category                            */
    SELECT
        product_category,
        month_start,
        SUM( "sale_price" )                       AS total_revenue,
        COUNT( DISTINCT "order_id" )              AS total_completed_orders,
        SUM( product_cost )                       AS total_cost
    FROM delivered_orders
    GROUP BY product_category, month_start
),
profit_calc AS (
    /* 3.  Add profit metrics                                                 */
    SELECT
        product_category,
        month_start,
        total_revenue,
        total_completed_orders,
        total_cost,
        ( total_revenue - total_cost )            AS total_profit,
        CASE WHEN total_cost <> 0
             THEN ( total_revenue - total_cost ) / total_cost
        END                                       AS profit_to_cost_ratio
    FROM agg
),
growth AS (
    /* 4.  Calculate month‑over‑month growth                                  */
    SELECT
        product_category,
        month_start,
        total_revenue,
        total_completed_orders,
        total_cost,
        total_profit,
        profit_to_cost_ratio,
        LAG( total_revenue ) OVER (PARTITION BY product_category
                                   ORDER BY month_start)  AS prev_revenue,
        LAG( total_completed_orders ) OVER (PARTITION BY product_category
                                            ORDER BY month_start) AS prev_orders
    FROM profit_calc
)
SELECT
    product_category,
    month_start,
    total_revenue,
    total_completed_orders,
    ROUND(
        CASE WHEN prev_revenue IS NULL OR prev_revenue = 0
             THEN NULL
             ELSE ( total_revenue - prev_revenue ) / prev_revenue * 100
        END , 2)                                      AS revenue_mom_growth_pct,
    ROUND(
        CASE WHEN prev_orders IS NULL OR prev_orders = 0
             THEN NULL
             ELSE ( total_completed_orders - prev_orders ) / prev_orders * 100
        END , 2)                                      AS orders_mom_growth_pct,
    total_cost,
    total_profit,
    ROUND( profit_to_cost_ratio , 4 )                 AS profit_to_cost_ratio
FROM growth
ORDER BY product_category,
         month_start;