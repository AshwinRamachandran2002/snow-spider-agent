WITH base AS (
    SELECT
        DATE_TRUNC(
            'month',
            TO_TIMESTAMP_NTZ("oi"."created_at" / 1000000)
        )                                             AS "month_start",
        "p"."name"                                    AS "product_name",
        "p"."brand"                                   AS "brand",
        "p"."category"                                AS "category",
        COUNT(*)                                      AS "total_sales",
        SUM("oi"."sale_price")                        AS "total_revenue"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS          AS "oi"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.PRODUCTS             AS "p"
         ON "oi"."product_id" = "p"."id"
    WHERE
        "oi"."status" = 'Complete'
        AND "p"."brand" IS NOT NULL
    GROUP BY
        DATE_TRUNC('month', TO_TIMESTAMP_NTZ("oi"."created_at" / 1000000)),
        "p"."name",
        "p"."brand",
        "p"."category"
),
ranked AS (
    SELECT
        "month_start",
        "product_name",
        "brand",
        "category",
        "total_sales",
        ROUND("total_revenue", 2)                     AS "total_revenue",
        ROW_NUMBER() OVER (
            PARTITION BY "month_start"
            ORDER BY "total_sales" DESC, "total_revenue" DESC
        )                                             AS "rn"
    FROM base
    WHERE "month_start" < '2024-07-01'
)
SELECT
    TO_CHAR("month_start", 'YYYY-MM')  AS "month",
    "product_name",
    "brand",
    "category",
    "total_sales",
    "total_revenue",
    'Complete'                         AS "order_status"
FROM ranked
WHERE "rn" = 1
ORDER BY "month_start";