WITH order_data AS (
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP_NTZ("OI"."created_at" / 1000000))      AS "month_start",
        "P"."name"                                                             AS "product_name",
        "P"."brand"                                                            AS "brand",
        "P"."category"                                                         AS "category",
        COUNT(*)                                                               AS "total_sales",
        SUM("OI"."sale_price")                                                 AS "total_revenue"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS         AS "OI"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS              AS "O"
         ON "OI"."order_id" = "O"."order_id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.PRODUCTS            AS "P"
         ON "OI"."product_id" = "P"."id"
    WHERE "O"."status" = 'Complete'                    -- only completed orders
      AND "P"."brand" IS NOT NULL                     -- require a non‑null brand
      AND DATE_TRUNC('month', TO_TIMESTAMP_NTZ("OI"."created_at" / 1000000))
            < '2024-07-01'                            -- exclude July 2024 and later
    GROUP BY
        "month_start", "P"."name", "P"."brand", "P"."category"
),

ranked AS (
    SELECT
        *,
        RANK() OVER (PARTITION BY "month_start"
                     ORDER BY "total_sales" DESC, "total_revenue" DESC) AS "rnk"
    FROM order_data
)

SELECT
    TO_CHAR("month_start", 'YYYY-MM')          AS "month",
    "product_name",
    "brand",
    "category",
    "total_sales",
    ROUND("total_revenue", 2)                  AS "total_revenue",
    'Complete'                                 AS "order_status"
FROM ranked
WHERE "rnk" = 1                                -- pick the single top performer each month
ORDER BY "month_start";