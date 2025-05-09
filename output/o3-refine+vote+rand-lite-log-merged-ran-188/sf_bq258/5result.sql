/* Monthly performance report per product category
   – only “Complete” order-items delivered before 2022-01-01 */

WITH monthly AS (         -- 1. aggregate monthly figures
    SELECT
        p."category",
        DATE_TRUNC('month',
                   TO_TIMESTAMP(oi."delivered_at" / 1000000))     AS month_start,
        SUM(oi."sale_price")                                     AS revenue,
        COUNT(*)                                                 AS completed_orders,
        SUM(p."cost")                                            AS total_cost,
        SUM(oi."sale_price" - p."cost")                          AS profit
    FROM   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  oi
    JOIN   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"      p
           ON oi."product_id" = p."id"
    WHERE  oi."status"       = 'Complete'
      AND  oi."delivered_at" IS NOT NULL
      AND  oi."delivered_at" < 1640995200000000                  -- 2022-01-01
    GROUP  BY p."category",
              DATE_TRUNC('month', TO_TIMESTAMP(oi."delivered_at" / 1000000))
),

monthly_with_prev AS (     -- 2. add previous-month values via window functions
    SELECT
        "category",
        month_start,
        TO_CHAR(month_start, 'YYYY-MM')                          AS year_month,
        revenue,
        completed_orders,
        total_cost,
        profit,
        LAG(revenue)         OVER (PARTITION BY "category"
                                   ORDER BY month_start)         AS prev_revenue,
        LAG(completed_orders) OVER (PARTITION BY "category"
                                   ORDER BY month_start)         AS prev_orders
    FROM   monthly
)

SELECT
    "category",
    year_month,
    revenue,
    completed_orders,
    /* month-over-month % growth */
    CASE
        WHEN prev_revenue IS NULL OR prev_revenue = 0 THEN NULL
        ELSE ROUND( (revenue - prev_revenue) / prev_revenue * 100, 4)
    END                                           AS revenue_pct_growth,
    CASE
        WHEN prev_orders  IS NULL OR prev_orders  = 0 THEN NULL
        ELSE ROUND( (completed_orders - prev_orders) / prev_orders * 100, 4)
    END                                           AS orders_pct_growth,
    total_cost,
    profit,
    CASE WHEN total_cost = 0 THEN NULL
         ELSE ROUND(profit / total_cost, 4)
    END                                           AS profit_to_cost_ratio
FROM   monthly_with_prev
ORDER  BY "category",
          year_month;