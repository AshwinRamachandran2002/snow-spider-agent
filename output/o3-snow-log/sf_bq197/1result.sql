/*  Monthly top-selling products (prior to 2024-07)  */
WITH sales_per_product_month AS (        -- aggregate sales for every product each month
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP(o."created_at"/1000000))          AS month_start ,
        p."name"                                                           AS product_name ,
        p."brand"                                                          AS brand ,
        p."category"                                                       AS category ,
        COUNT(*)                                                           AS total_sales ,          -- volume
        SUM(oi."sale_price")                                               AS total_revenue
    FROM  THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS  oi
    JOIN  THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS       o  ON oi."order_id" = o."order_id"
    JOIN  THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.PRODUCTS     p  ON oi."product_id" = p."id"
    WHERE   o."status" = 'Complete'                                  -- only completed orders
        AND p."brand" IS NOT NULL                                    -- exclude un-branded products
        AND DATE_TRUNC('month', TO_TIMESTAMP(o."created_at"/1000000)) < '2024-07-01'
    GROUP BY  month_start, product_name, brand, category
),

ranked AS (                           -- pick the best seller per month
    SELECT  *,
            ROW_NUMBER() OVER (PARTITION BY month_start
                               ORDER BY total_sales DESC,
                                        total_revenue DESC)        AS rn
    FROM    sales_per_product_month
)

SELECT
    TO_CHAR(month_start, 'YYYY-MM')        AS month ,
    product_name ,
    brand ,
    category ,
    total_sales ,
    ROUND(total_revenue, 2)                AS total_revenue ,
    'Complete'                             AS order_status
FROM   ranked
WHERE  rn = 1                              -- keep only the monthly winner
ORDER  BY month_start;