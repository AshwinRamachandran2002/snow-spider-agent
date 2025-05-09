WITH monthly_product_sales AS (  /* aggregate product performance by month */
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP("oi"."created_at"/1000000))       AS "month",
        "oi"."product_id",
        "p"."name"                                                        AS "product_name",
        "p"."brand",
        "p"."category",
        COUNT(*)                                                          AS "total_sales",
        SUM("oi"."sale_price")                                            AS "total_revenue"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS  AS "oi"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.PRODUCTS     AS "p"
          ON "oi"."product_id" = "p"."id"
    WHERE "oi"."status" = 'Complete'                 -- only completed orders
      AND "p"."brand" IS NOT NULL                    -- exclude products without a brand
      AND DATE_TRUNC('month', TO_TIMESTAMP("oi"."created_at"/1000000))
            < DATE '2024-07-01'                      -- months prior to July-2024
    GROUP BY
        DATE_TRUNC('month', TO_TIMESTAMP("oi"."created_at"/1000000)),
        "oi"."product_id",
        "p"."name",
        "p"."brand",
        "p"."category"
),

monthly_top_product AS (  /* pick the single best-seller per month */
    SELECT *
    FROM monthly_product_sales
    QUALIFY ROW_NUMBER() OVER (
                PARTITION BY "month"
                ORDER BY "total_sales" DESC,
                         "total_revenue" DESC
            ) = 1
)

SELECT
    TO_CHAR("month", 'YYYY-MM')                        AS "month",
    "product_name",
    "brand",
    "category",
    "total_sales",
    ROUND("total_revenue", 2)                          AS "total_revenue",
    'Complete'                                         AS "order_status"
FROM monthly_top_product
ORDER BY "month" ASC;