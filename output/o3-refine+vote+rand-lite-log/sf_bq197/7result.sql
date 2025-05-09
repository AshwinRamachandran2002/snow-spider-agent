WITH monthly_product_sales AS (   -- 1.  aggregate item‑level sales by product & month
    SELECT
        DATE_TRUNC('month',
                   TO_TIMESTAMP_NTZ("oi"."created_at"/1000000))                          AS "month",
        "p"."id"                                                                      AS "product_id",
        "p"."name"                                                                    AS "product_name",
        "p"."brand"                                                                   AS "brand",
        "p"."category"                                                                AS "category",
        COUNT(*)                                                                      AS "total_sales",     -- units
        SUM("oi"."sale_price")                                                        AS "total_revenue"    -- $
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS        AS "oi"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS             AS "o"
         ON  "oi"."order_id" = "o"."order_id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.PRODUCTS           AS "p"
         ON  "oi"."product_id" = "p"."id"
    WHERE "o"."status"  = 'Complete'        -- only fully completed orders
      AND "oi"."status" = 'Complete'        -- only fully completed order‑items
      AND "p"."brand"  IS NOT NULL          -- ignore products without a brand
      AND DATE_TRUNC('month',
                     TO_TIMESTAMP_NTZ("oi"."created_at"/1000000)) < DATE '2024-07-01'
    GROUP BY 1,2,3,4,5
), ranked_products AS (           -- 2. pick the top product per month
    SELECT
        "month",
        "product_name",
        "brand",
        "category",
        "total_sales",
        "total_revenue",
        ROW_NUMBER() OVER (PARTITION BY "month"
                           ORDER BY "total_sales" DESC,
                                    "total_revenue" DESC)        AS "rn"
    FROM monthly_product_sales
)
SELECT
    TO_CHAR("month", 'YYYY-MM')                 AS "month",
    "product_name",
    "brand",
    "category",
    "total_sales",
    ROUND("total_revenue", 2)                   AS "total_revenue",
    'Complete'                                  AS "order_status"   -- all rows come from complete orders
FROM ranked_products
WHERE "rn" = 1                       -- best‑seller for each month
ORDER BY "month";