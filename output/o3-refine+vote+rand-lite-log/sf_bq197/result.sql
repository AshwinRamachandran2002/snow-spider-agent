WITH monthly_product_sales AS (
    SELECT
        DATE_TRUNC('MONTH', TO_TIMESTAMP_NTZ(o."created_at" / 1e6))          AS "order_month",
        p."name"                                                            AS "product_name",
        p."brand"                                                           AS "brand",
        p."category"                                                        AS "category",
        COUNT(*)                                                            AS "total_sales",
        SUM(oi."sale_price")                                                AS "total_revenue"
    FROM
        "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS"  oi
        JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDERS"  o  ON oi."order_id" = o."order_id"
        JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."PRODUCTS" p  ON oi."product_id" = p."id"
    WHERE
        o."status" = 'Complete'                                  -- use only completed orders
        AND p."brand" IS NOT NULL                                -- ignore products without a brand
        AND TO_TIMESTAMP_NTZ(o."created_at" / 1e6) < '2024-07-01'-- months prior to July‑2024
    GROUP BY
        "order_month", p."name", p."brand", p."category"
),

ranked_monthly AS (
    SELECT
        "order_month",
        "product_name",
        "brand",
        "category",
        "total_sales",
        ROUND("total_revenue", 2)                                AS "total_revenue",
        'Complete'                                               AS "order_status",
        ROW_NUMBER() OVER (
            PARTITION BY "order_month"
            ORDER BY "total_sales" DESC, "total_revenue" DESC
        )                                                        AS "rn"
    FROM
        monthly_product_sales
)

SELECT
    TO_CHAR("order_month", 'YYYY-MM') AS "month",
    "product_name",
    "brand",
    "category",
    "total_sales",
    "total_revenue",
    "order_status"
FROM
    ranked_monthly
WHERE
    "rn" = 1                       -- pick the single top product per month
ORDER BY
    "month";