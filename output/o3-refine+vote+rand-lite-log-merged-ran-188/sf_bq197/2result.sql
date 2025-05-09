WITH monthly_product_sales AS (
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP(o."created_at" / 1000000))  AS month_start,
        p."name"                                                    AS product_name,
        p."brand"                                                   AS brand,
        p."category"                                                AS category,
        COUNT(*)                                                    AS total_sales,
        SUM(oi."sale_price")                                        AS total_revenue
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS      o
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS oi
         ON oi."order_id" = o."order_id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.PRODUCTS    p
         ON p."id" = oi."product_id"
    WHERE o."status" = 'Complete'
      AND p."brand" IS NOT NULL
      AND DATE_TRUNC('month', TO_TIMESTAMP(o."created_at" / 1000000)) < DATE '2024-07-01'
    GROUP BY month_start, product_name, brand, category
), ranked_monthly_sales AS (
    SELECT
        month_start,
        product_name,
        brand,
        category,
        total_sales,
        ROUND(total_revenue, 2)                                    AS total_revenue,
        ROW_NUMBER() OVER (
            PARTITION BY month_start
            ORDER BY total_sales DESC, total_revenue DESC
        )                                                         AS rn
    FROM monthly_product_sales
)
SELECT
    TO_CHAR(month_start, 'YYYY-MM') AS "MONTH",
    product_name                    AS "PRODUCT_NAME",
    brand                           AS "BRAND",
    category                        AS "CATEGORY",
    total_sales                     AS "TOTAL_SALES",
    total_revenue                   AS "TOTAL_REVENUE",
    'Complete'                      AS "ORDER_STATUS"
FROM ranked_monthly_sales
WHERE rn = 1
ORDER BY month_start;