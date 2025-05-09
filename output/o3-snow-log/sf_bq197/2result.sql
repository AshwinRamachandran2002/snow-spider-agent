WITH agg AS (
    SELECT
        DATE_TRUNC('MONTH', TO_TIMESTAMP_LTZ("oi"."created_at" / 1000000))                               AS month_start,
        "p"."name"                                                                                       AS product_name,
        "p"."brand"                                                                                      AS brand,
        "p"."category"                                                                                   AS category,
        COUNT(*)                                                                                         AS total_sales,
        SUM("oi"."sale_price")                                                                           AS total_revenue
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"        AS "oi"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"             AS "o"
         ON "oi"."order_id" = "o"."order_id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"           AS "p"
         ON "oi"."product_id" = "p"."id"
    WHERE "o"."status" = 'Complete'
      AND "p"."brand" IS NOT NULL
      AND TO_TIMESTAMP_LTZ("oi"."created_at" / 1000000) < DATE '2024-07-01'
    GROUP BY
        month_start,
        product_name,
        brand,
        category
),

ranked AS (
    SELECT
        month_start,
        product_name,
        brand,
        category,
        total_sales,
        ROUND(total_revenue, 2)                                                                         AS rounded_total_revenue,
        ROW_NUMBER() OVER (PARTITION BY month_start
                           ORDER BY total_sales DESC NULLS LAST,
                                    total_revenue DESC NULLS LAST)                                      AS rn
    FROM agg
)

SELECT
    TO_CHAR(month_start, 'YYYY-MM')                                                                     AS "month",
    product_name                                                                                        AS "product_name",
    brand                                                                                               AS "brand",
    category                                                                                            AS "category",
    total_sales                                                                                         AS "total_sales",
    rounded_total_revenue                                                                               AS "total_revenue",
    'Complete'                                                                                          AS "order_status"
FROM ranked
WHERE rn = 1
ORDER BY month_start;