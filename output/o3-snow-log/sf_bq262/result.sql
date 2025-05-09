WITH order_item_data AS (   /* 1.  Prepare item–level facts for the target period */
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP("created_at"/1000000))  AS order_month ,
        p."category"                                            AS product_category ,
        oi."order_id"                                           AS order_id ,
        oi."sale_price"                                         AS revenue ,
        (oi."sale_price" - p."cost")                            AS profit
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"     p
          ON oi."product_id" = p."id"
    WHERE DATE_TRUNC('month', TO_TIMESTAMP("created_at"/1000000))
          BETWEEN DATE '2019-06-01' AND DATE '2019-12-31'
),

/* 2.  Aggregate to month + category */
category_month AS (
    SELECT
        order_month ,
        product_category ,
        COUNT(DISTINCT order_id)        AS total_orders ,
        SUM(revenue)                    AS total_revenue ,
        SUM(profit)                     AS total_profit
    FROM order_item_data
    GROUP BY order_month, product_category
),

/* 3.  Add month-over-month growth using the previous month (June 2019 is the baseline) */
category_month_growth AS (
    SELECT
        order_month ,
        product_category ,
        total_orders ,
        total_revenue ,
        total_profit ,
        ROUND(
              (total_orders -  LAG(total_orders)  OVER (PARTITION BY product_category ORDER BY order_month))
              / NULLIF(LAG(total_orders)  OVER (PARTITION BY product_category ORDER BY order_month),0)
        ,4)                              AS orders_mom_growth ,
        ROUND(
              (total_revenue - LAG(total_revenue) OVER (PARTITION BY product_category ORDER BY order_month))
              / NULLIF(LAG(total_revenue) OVER (PARTITION BY product_category ORDER BY order_month),0)
        ,4)                              AS revenue_mom_growth ,
        ROUND(
              (total_profit -  LAG(total_profit)  OVER (PARTITION BY product_category ORDER BY order_month))
              / NULLIF(LAG(total_profit)  OVER (PARTITION BY product_category ORDER BY order_month),0)
        ,4)                              AS profit_mom_growth
    FROM category_month
)

/* 4.  Final result: July–December 2019 only, ordered as requested */
SELECT
    TO_CHAR(order_month, 'YYYY-MM')  AS "month" ,
    product_category                AS "product_category" ,
    total_orders                    AS "total_orders" ,
    total_revenue                   AS "total_revenue" ,
    total_profit                    AS "total_profit" ,
    orders_mom_growth               AS "orders_mom_growth" ,
    revenue_mom_growth              AS "revenue_mom_growth" ,
    profit_mom_growth               AS "profit_mom_growth"
FROM category_month_growth
WHERE order_month >= DATE '2019-07-01'      -- omit June from the output
ORDER BY "month", "product_category";