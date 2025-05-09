WITH monthly_product_sales AS (
    SELECT DATE_TRUNC('month', TO_TIMESTAMP_NTZ(oi."created_at" / 1000000)) AS "month",
           oi."product_id",
           COUNT(*)                       AS "total_sales",
           SUM(oi."sale_price")           AS "total_revenue"
    FROM   "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS"  oi
    JOIN   "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDERS"       o
           ON o."order_id" = oi."order_id"
    JOIN   "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."PRODUCTS"     p
           ON p."id" = oi."product_id"
    WHERE  oi."status" = 'Complete'
      AND  o."status" = 'Complete'
      AND  p."brand" IS NOT NULL
      AND  DATE_TRUNC('month', TO_TIMESTAMP_NTZ(oi."created_at" / 1000000)) < '2024-07-01'
    GROUP  BY 1, oi."product_id"
), ranked AS (
    SELECT mps.*,
           ROW_NUMBER() OVER (PARTITION BY mps."month"
                              ORDER BY mps."total_sales" DESC,
                                       mps."total_revenue" DESC) AS rn
    FROM   monthly_product_sales mps
)
SELECT  r."month"                            AS month,
        p."name"                             AS product_name,
        p."brand",
        p."category",
        r."total_sales",
        ROUND(r."total_revenue", 4)          AS total_revenue,
        'Complete'                           AS order_status
FROM    ranked r
JOIN    "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."PRODUCTS" p
        ON p."id" = r."product_id"
WHERE   r.rn = 1
ORDER BY r."month";