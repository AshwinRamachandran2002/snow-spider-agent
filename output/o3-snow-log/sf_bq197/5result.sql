/*  Monthly best-selling products (up to – but not including – July 2024)  */
WITH complete_orders AS (
    SELECT 
        "order_id",
        "created_at",
        "status"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS
    WHERE "status" = 'Complete'
      AND TO_DATE(TO_TIMESTAMP_NTZ("created_at" / 1000000)) < DATE '2024-07-01'
), 

order_sales AS (
    /* sales volume & revenue for every product in every month                */
    SELECT
        DATE_TRUNC('month', TO_DATE(TO_TIMESTAMP_NTZ(co."created_at" / 1000000)))   AS "order_month",
        oi."product_id",
        COUNT(*)                                                                  AS "total_sales",
        SUM(oi."sale_price")                                                      AS "total_revenue"
    FROM complete_orders      co
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS  oi
         ON oi."order_id" = co."order_id"
    GROUP BY 1, 2
),

product_info AS (
    SELECT 
        p."id"         AS "product_id",
        p."name",
        p."brand",
        p."category"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.PRODUCTS p
    WHERE p."brand" IS NOT NULL
),

ranked_products AS (
    SELECT
        os."order_month",
        pi."name"                                   AS "product_name",
        pi."brand",
        pi."category",
        os."total_sales",
        ROUND(os."total_revenue", 2)                AS "total_revenue",
        'Complete'                                  AS "order_status",
        ROW_NUMBER() OVER (PARTITION BY os."order_month"
                           ORDER BY os."total_sales" DESC,
                                    os."total_revenue" DESC)  AS rn
    FROM order_sales   os
    JOIN product_info  pi
         ON pi."product_id" = os."product_id"
)

SELECT
    TO_CHAR("order_month", 'YYYY-MM')  AS "month",
    "product_name",
    "brand",
    "category",
    "total_sales",
    "total_revenue",
    "order_status"
FROM ranked_products
WHERE rn = 1
ORDER BY "order_month";