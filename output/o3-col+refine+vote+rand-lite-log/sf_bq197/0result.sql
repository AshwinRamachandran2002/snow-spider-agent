WITH sales_per_product_month AS (
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP(oi."created_at" / 1000000))  AS "month",
        p."name"                                                     AS "product_name",
        p."brand",
        p."category",
        COUNT(*)                                                     AS "total_sales",
        ROUND(SUM(oi."sale_price"), 2)                               AS "total_revenue"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"     p
        ON oi."product_id" = p."id"
    WHERE oi."status" = 'Complete'
      AND p."brand" IS NOT NULL
      AND DATE_TRUNC('month', TO_TIMESTAMP(oi."created_at" / 1000000)) < '2024-07-01'
    GROUP BY 1,2,3,4
), ranked AS (
    SELECT
        spm.*,
        RANK() OVER (
            PARTITION BY spm."month"
            ORDER BY spm."total_sales" DESC,
                     spm."total_revenue" DESC
        ) AS "sales_rank"
    FROM sales_per_product_month spm
)
SELECT
    "month",
    "product_name",
    "brand",
    "category",
    "total_sales",
    "total_revenue",
    'Complete' AS "order_status"
FROM ranked
WHERE "sales_rank" = 1
ORDER BY "month";