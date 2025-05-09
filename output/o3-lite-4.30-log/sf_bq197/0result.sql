WITH monthly_sales AS (
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP(oi."created_at" / 1000000)) AS "month",
        p."name"        AS "product_name",
        p."brand",
        p."category",
        COUNT(*)        AS "total_sales",
        ROUND(SUM(oi."sale_price"), 4) AS "total_revenue",
        'Complete'      AS "order_status"
    FROM
        THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS  oi
    JOIN
        THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.PRODUCTS     p
          ON p."id" = oi."product_id"
    WHERE
        oi."status" = 'Complete'
        AND p."brand" IS NOT NULL
        AND DATE_TRUNC('month', TO_TIMESTAMP(oi."created_at" / 1000000)) < '2024-07-01'
    GROUP BY
        1, 2, 3, 4
), ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY "month"
            ORDER BY "total_sales" DESC,
                     "total_revenue" DESC
        ) AS rn
    FROM
        monthly_sales
)
SELECT
    "month",
    "product_name",
    "brand",
    "category",
    "total_sales",
    "total_revenue",
    "order_status"
FROM
    ranked
WHERE
    rn = 1
ORDER BY
    "month";