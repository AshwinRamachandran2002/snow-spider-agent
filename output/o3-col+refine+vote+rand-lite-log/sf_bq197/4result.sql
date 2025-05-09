WITH monthly_product_sales AS (
    SELECT
        DATE_TRUNC(
            'MONTH',
            TO_TIMESTAMP_NTZ(oi."created_at" / 1000000)
        )                                                     AS "month",
        p."name"                                              AS "product_name",
        p."brand",
        p."category",
        COUNT(*)                                              AS "total_sales",
        ROUND(SUM(oi."sale_price"), 2)                        AS "rounded_total_revenue"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"   oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"        o
      ON oi."order_id" = o."order_id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"      p
      ON oi."product_id" = p."id"
    WHERE oi."status" = 'Complete'
      AND o."status"  = 'Complete'
      AND p."brand"   IS NOT NULL
      AND DATE_TRUNC(
            'MONTH',
            TO_TIMESTAMP_NTZ(oi."created_at" / 1000000)
          ) < '2024-07-01'        -- “prior to July 2024”
    GROUP BY 1, 2, 3, 4
),

ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY "month"
            ORDER BY
                "total_sales"            DESC NULLS LAST,
                "rounded_total_revenue"  DESC NULLS LAST
        ) AS "rn"
    FROM monthly_product_sales
)

SELECT
    "month",
    "product_name",
    "brand",
    "category",
    "total_sales",
    "rounded_total_revenue",
    'Complete'                      AS "order_status"
FROM ranked
WHERE "rn" = 1
ORDER BY "month";