WITH base AS (   -- all completed order items before July-2024
    SELECT
        DATE_TRUNC('MONTH', TO_TIMESTAMP_NTZ(o."created_at" / 1000000))      AS order_month,
        oi."product_id"                                                     AS PRODUCT_ID,
        p."name"                                                            AS PRODUCT_NAME,
        p."brand"                                                           AS PRODUCT_BRAND,
        p."category"                                                        AS PRODUCT_CATEGORY,
        oi."sale_price"                                                     AS SALE_PRICE
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"       o  ON oi."order_id" = o."order_id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"     p  ON oi."product_id" = p."id"
    WHERE o."status" = 'Complete'
      AND p."brand" IS NOT NULL
      AND DATE_TRUNC('MONTH', TO_TIMESTAMP_NTZ(o."created_at" / 1000000)) < DATE '2024-07-01'
),

agg AS (   -- monthly totals by product
    SELECT
        order_month,
        PRODUCT_ID,
        PRODUCT_NAME,
        PRODUCT_BRAND,
        PRODUCT_CATEGORY,
        COUNT(*)          AS total_sales,
        SUM(SALE_PRICE)   AS total_revenue
    FROM base
    GROUP BY
        order_month,
        PRODUCT_ID,
        PRODUCT_NAME,
        PRODUCT_BRAND,
        PRODUCT_CATEGORY
),

ranked AS (   -- pick best-seller per month (volume then revenue)
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY order_month
            ORDER BY total_sales DESC, total_revenue DESC
        ) AS rn
    FROM agg
)

SELECT
    TO_CHAR(order_month, 'YYYY-MM')     AS month,
    PRODUCT_NAME                        AS product_name,
    PRODUCT_BRAND                       AS brand,
    PRODUCT_CATEGORY                    AS category,
    total_sales,
    ROUND(total_revenue, 2)             AS total_revenue,
    'Complete'                          AS order_status
FROM ranked
WHERE rn = 1
ORDER BY order_month;