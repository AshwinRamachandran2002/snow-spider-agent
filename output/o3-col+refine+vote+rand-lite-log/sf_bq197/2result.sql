/*  Monthly top-selling product (by volume, then revenue) before 2024-07  */
WITH ranked_monthly AS (
    SELECT
        DATE_TRUNC(
            'month',
            TO_TIMESTAMP(oi."created_at" / 1000000)
        )                                                AS "order_month",
        p."name"                                         AS "product_name",
        p."brand",
        p."category",
        COUNT(*)                                         AS "total_sales",
        SUM(oi."sale_price")                             AS "total_revenue",
        ROW_NUMBER() OVER (
            PARTITION BY DATE_TRUNC('month', TO_TIMESTAMP(oi."created_at" / 1000000))
            ORDER BY
                COUNT(*)        DESC,      -- 1st criterion: sales volume
                SUM(oi."sale_price") DESC  -- 2nd criterion: total revenue
        )                                               AS "rnk"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS" oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"    p
          ON oi."product_id" = p."id"
    WHERE oi."status" = 'Complete'
      AND p."brand" IS NOT NULL
      AND TO_TIMESTAMP(oi."created_at" / 1000000) < '2024-07-01'::DATE
    GROUP BY 1,2,3,4
)

SELECT
    TO_CHAR("order_month", 'YYYY-MM')            AS "month",
    "product_name",
    "brand",
    "category",
    "total_sales",
    ROUND("total_revenue", 2)                    AS "total_revenue",
    'Complete'                                   AS "order_status"
FROM ranked_monthly
WHERE "rnk" = 1          -- keep only the single best-seller per month
ORDER BY "order_month";