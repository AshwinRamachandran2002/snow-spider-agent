WITH order_item_details AS (
    /*---------------------------------------------------------
      Gather every order‑item between 2019‑06‑01 and 2019‑12‑31,
      attaching its product category, selling price and cost.
    ----------------------------------------------------------*/
    SELECT
        DATE_TRUNC('month',
                   TO_TIMESTAMP_NTZ(oi."created_at" / 1000000)
                  )                                        AS month_date,
        COALESCE(inv."product_category", 'Unknown')        AS category,
        oi."order_id"                                      AS order_id,
        COALESCE(oi."sale_price", 0)                       AS sale_price,
        COALESCE(inv."cost", 0)                            AS cost
    FROM "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS"        AS oi
    LEFT JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."INVENTORY_ITEMS" AS inv
           ON oi."inventory_item_id" = inv."id"
    WHERE DATE_TRUNC('month', TO_TIMESTAMP_NTZ(oi."created_at" / 1000000))
          BETWEEN '2019-06-01' AND '2019-12-01'
),

/*-------------------------------------------------------------
  Aggregate to month & category level
--------------------------------------------------------------*/
monthly_summary AS (
    SELECT
        month_date,
        TO_CHAR(month_date, 'YYYY-MM')                    AS month,
        category,
        COUNT(DISTINCT order_id)                          AS total_orders,
        SUM(sale_price)                                   AS total_revenue,
        SUM(sale_price - cost)                            AS total_profit
    FROM order_item_details
    GROUP BY month_date, category
),

/*-------------------------------------------------------------
  Compute month‑over‑month growth using LAG(), keeping June
  only as a base for growth calculations.
--------------------------------------------------------------*/
monthly_with_growth AS (
    SELECT
        month,
        category,
        total_orders,
        total_revenue,
        total_profit,
        ROUND( (total_orders
                - LAG(total_orders) OVER (PARTITION BY category ORDER BY month_date))
               / NULLIF(LAG(total_orders) OVER (PARTITION BY category ORDER BY month_date),0)
             , 4)                                          AS orders_mom_growth,
        ROUND( (total_revenue
                - LAG(total_revenue) OVER (PARTITION BY category ORDER BY month_date))
               / NULLIF(LAG(total_revenue) OVER (PARTITION BY category ORDER BY month_date),0)
             , 4)                                          AS revenue_mom_growth,
        ROUND( (total_profit
                - LAG(total_profit) OVER (PARTITION BY category ORDER BY month_date))
               / NULLIF(LAG(total_profit) OVER (PARTITION BY category ORDER BY month_date),0)
             , 4)                                          AS profit_mom_growth,
        month_date
    FROM monthly_summary
)

/*-------------------------------------------------------------
  Final result: July‑2019 through December‑2019
--------------------------------------------------------------*/
SELECT
    month,
    category,
    total_orders,
    total_revenue,
    total_profit,
    orders_mom_growth,
    revenue_mom_growth,
    profit_mom_growth
FROM monthly_with_growth
WHERE month >= '2019-07'
ORDER BY month_date, category;