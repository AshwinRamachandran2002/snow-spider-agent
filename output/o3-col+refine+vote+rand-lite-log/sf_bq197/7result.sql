WITH monthly_product_sales AS (
    SELECT
        DATE_TRUNC(
            'month',
            TO_TIMESTAMP_NTZ(oi."created_at" / 1000000)
        )                                   AS "month",
        p."name"                            AS "product_name",
        p."brand",
        p."category",
        COUNT(*)                            AS "total_sales",
        SUM(oi."sale_price")                AS "total_revenue",
        ROW_NUMBER() OVER (
            PARTITION BY DATE_TRUNC(
                'month',
                TO_TIMESTAMP_NTZ(oi."created_at" / 1000000)
            )
            ORDER BY
                COUNT(*)        DESC,
                SUM(oi."sale_price") DESC
        )                                   AS "rnk"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS   oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.PRODUCTS      p
      ON p."id" = oi."product_id"
    WHERE oi."status" = 'Complete'
      AND p."brand" IS NOT NULL
      AND DATE_TRUNC(
              'month',
              TO_TIMESTAMP_NTZ(oi."created_at" / 1000000)
          ) < '2024-07-01'        -- exclude July-2024 and beyond
    GROUP BY
        1, 2, 3, 4
)
SELECT
    "month",
    "product_name",
    "brand",
    "category",
    "total_sales",
    ROUND("total_revenue", 2)      AS "total_revenue",
    'Complete'                     AS "order_status"
FROM monthly_product_sales
WHERE "rnk" = 1
ORDER BY "month";