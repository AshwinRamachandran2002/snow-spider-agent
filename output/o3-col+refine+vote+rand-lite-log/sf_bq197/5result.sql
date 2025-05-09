WITH monthly_product_sales AS (
    SELECT 
        TO_CHAR(TO_TIMESTAMP_NTZ(oi."created_at" / 1000000), 'YYYY-MM') AS "order_month",
        oi."product_id",
        COUNT(*)                                                       AS "total_sales",
        SUM(oi."sale_price")                                           AS "total_revenue"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"     p
      ON oi."product_id" = p."id"
    WHERE oi."status" = 'Complete'
      AND p."brand" IS NOT NULL
    GROUP BY 1, 2
), ranked_products AS (
    SELECT 
        mps.*,
        ROW_NUMBER() OVER (
            PARTITION BY mps."order_month"
            ORDER BY mps."total_sales" DESC, mps."total_revenue" DESC
        ) AS "rn"
    FROM monthly_product_sales mps
)
SELECT 
    rp."order_month",
    pr."name"                         AS "product_name",
    pr."brand",
    pr."category",
    rp."total_sales",
    ROUND(rp."total_revenue", 2)      AS "rounded_revenue",
    'Complete'                        AS "order_status"
FROM ranked_products rp
JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS" pr
  ON rp."product_id" = pr."id"
WHERE rp."rn" = 1
  AND rp."order_month" < '2024-07'
ORDER BY rp."order_month";