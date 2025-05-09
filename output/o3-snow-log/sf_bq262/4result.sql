WITH monthly_category AS (
    /* 1.  Aggregate June–December 2019 figures at (month , product_category) level */
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP(o."created_at" / 1000000))                     AS month_start ,
        TO_CHAR(DATE_TRUNC('month', TO_TIMESTAMP(o."created_at" / 1000000)), 'YYYY-MM') AS month ,
        p."category"                                                                   AS product_category ,
        COUNT(DISTINCT oi."order_id")                                                  AS total_orders ,
        SUM(oi."sale_price")                                                           AS total_revenue ,
        SUM(oi."sale_price" - p."cost")                                                AS total_profit
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS      oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS           o  ON oi."order_id" = o."order_id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.PRODUCTS         p  ON oi."product_id" = p."id"
    WHERE DATE_TRUNC('month', TO_TIMESTAMP(o."created_at" / 1000000))
              BETWEEN '2019-06-01' AND '2019-12-01'
    GROUP BY month_start , month , product_category
),
growth AS (
    /* 2.  Bring previous-month numbers so we can compute MoM growth */
    SELECT
        month_start ,
        month ,
        product_category ,
        total_orders ,
        total_revenue ,
        total_profit ,
        LAG(total_orders)  OVER (PARTITION BY product_category ORDER BY month_start) AS prev_orders ,
        LAG(total_revenue) OVER (PARTITION BY product_category ORDER BY month_start) AS prev_revenue ,
        LAG(total_profit)  OVER (PARTITION BY product_category ORDER BY month_start) AS prev_profit
    FROM monthly_category
)
SELECT
    month ,
    product_category ,
    total_orders ,
    total_revenue ,
    total_profit ,
    ROUND( (total_orders  - prev_orders ) / NULLIF(prev_orders ,0) , 4) AS orders_mom_growth ,
    ROUND( (total_revenue - prev_revenue) / NULLIF(prev_revenue,0) , 4) AS revenue_mom_growth ,
    ROUND( (total_profit  - prev_profit ) / NULLIF(prev_profit ,0) , 4) AS profit_mom_growth
FROM growth
WHERE month <> '2019-06'          -- omit June from final output but keep it for MoM base
ORDER BY month ASC , product_category ASC;