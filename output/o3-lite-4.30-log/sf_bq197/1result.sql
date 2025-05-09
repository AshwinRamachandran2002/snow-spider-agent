WITH monthly_product_sales AS (
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP(oi."created_at" / 1000000)) AS "month",
        p."name"                                                     AS "product_name",
        p."brand",
        p."category",
        COUNT(*)                                                     AS "total_sales",
        ROUND(SUM(oi."sale_price"), 4)                               AS "total_revenue"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"       o
      ON o."order_id" = oi."order_id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"     p
      ON p."id" = oi."product_id"
    WHERE oi."status" = 'Complete'
      AND o."status" = 'Complete'
      AND p."brand" IS NOT NULL
      AND TO_TIMESTAMP(oi."created_at" / 1000000) < DATE '2024-07-01'
    GROUP BY
        "month",
        p."name",
        p."brand",
        p."category"
),
ranked AS (
    SELECT
        mps.*,
        ROW_NUMBER() OVER (
            PARTITION BY mps."month"
            ORDER BY mps."total_sales" DESC,
                     mps."total_revenue" DESC
        ) AS rn
    FROM monthly_product_sales mps
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
WHERE rn = 1
ORDER BY "month";