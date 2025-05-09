WITH monthly_product_sales AS (
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP_NTZ(oi."created_at" / 1000000))                 AS "month",
        oi."product_id",
        COUNT(*)                                                                         AS "total_sales",
        ROUND(SUM(oi."sale_price"))                                                      AS "rounded_total_revenue"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS  oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS       o  ON oi."order_id" = o."order_id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.PRODUCTS     p  ON oi."product_id" = p."id"
    WHERE o."status" = 'Complete'
      AND p."brand"  IS NOT NULL
      AND DATE_TRUNC('month', TO_TIMESTAMP_NTZ(oi."created_at" / 1000000)) < '2024-07-01'::DATE
    GROUP BY 1, 2
),
ranked_products AS (
    SELECT
        m.*,
        ROW_NUMBER() OVER (PARTITION BY m."month"
                           ORDER BY m."total_sales" DESC NULLS LAST,
                                    m."rounded_total_revenue" DESC NULLS LAST) AS rn
    FROM monthly_product_sales m
)
SELECT
    r."month",
    p."name"      AS "product_name",
    p."brand",
    p."category",
    r."total_sales",
    r."rounded_total_revenue",
    'Complete'    AS "order_status"
FROM ranked_products r
JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.PRODUCTS p
  ON r."product_id" = p."id"
WHERE r.rn = 1
ORDER BY r."month";