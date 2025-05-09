/*-----------------------------------------------------------------------
  Monthly performance of completed orders delivered before 2022,
  broken out by product category.
-----------------------------------------------------------------------*/
WITH completed_items AS (      -- every line-item in a *completed* order
    SELECT
        pr."category"                                            AS product_category,
        DATE_TRUNC('month', TO_TIMESTAMP(ord."delivered_at"/1e6)) AS delivery_month,
        oi."sale_price"                                          AS sale_price,
        pr."cost"                                                AS product_cost,
        ord."order_id"                                           AS order_id
    FROM  "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDERS"       ord
    JOIN  "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS"  oi
          ON ord."order_id" = oi."order_id"
    JOIN  "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."PRODUCTS"     pr
          ON oi."product_id" = pr."id"
    WHERE ord."status" = 'Complete'
      AND ord."delivered_at" IS NOT NULL
      AND ord."delivered_at" > 0                       -- screens-out NaN rows
      AND TO_TIMESTAMP(ord."delivered_at"/1e6) < '2022-01-01'::DATE
),  /*------------------------------------------------------------------*/
monthly_agg AS (               -- month-level roll-up
    SELECT
        product_category,
        delivery_month,
        SUM(sale_price)                              AS total_revenue,
        COUNT(DISTINCT order_id)                     AS total_completed_orders,
        SUM(product_cost)                            AS total_cost,
        SUM(sale_price) - SUM(product_cost)          AS total_profit,
        (SUM(sale_price) - SUM(product_cost))
            / NULLIF(SUM(product_cost),0)            AS profit_to_cost_ratio
    FROM completed_items
    GROUP BY product_category, delivery_month
)
SELECT
    product_category,
    TO_CHAR(delivery_month,'YYYY-MM')                              AS year_month,

    /* core KPIs */
    total_revenue,
    total_completed_orders,
    total_cost,
    total_profit,
    profit_to_cost_ratio,

    /* MoM growth calculations */
    ROUND(
        (total_revenue
         - LAG(total_revenue) OVER (PARTITION BY product_category
                                    ORDER BY delivery_month))
        / NULLIF(LAG(total_revenue) OVER (PARTITION BY product_category
                                          ORDER BY delivery_month),0)
        * 100, 4)                                  AS mom_revenue_growth_pct,

    ROUND(
        (total_completed_orders
         - LAG(total_completed_orders) OVER (PARTITION BY product_category
                                             ORDER BY delivery_month))
        / NULLIF(LAG(total_completed_orders) OVER (PARTITION BY product_category
                                                   ORDER BY delivery_month),0)
        * 100, 4)                                  AS mom_orders_growth_pct
FROM   monthly_agg
ORDER  BY product_category, delivery_month NULLS LAST;