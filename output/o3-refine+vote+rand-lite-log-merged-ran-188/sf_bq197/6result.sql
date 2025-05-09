WITH monthly_product_sales AS (
    /* 1.  Aggregate sales & revenue per product per month                     */
    SELECT
        DATE_TRUNC(
            'month',
            TO_TIMESTAMP_NTZ(o."created_at" / 1000000)
        )                                                 AS "order_month",
        oi."product_id"                                   AS "product_id",
        COUNT(*)                                          AS "total_sales",
        SUM(oi."sale_price")                              AS "total_revenue"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"        o
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"   oi
          ON oi."order_id" = o."order_id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"      p
          ON p."id" = oi."product_id"
    WHERE
          o."status" = 'Complete'                  /* only completed orders   */
      AND p."brand" IS NOT NULL                    /* brand must be present   */
      AND DATE_TRUNC(
              'month',
              TO_TIMESTAMP_NTZ(o."created_at" / 1000000)
          ) < '2024-07-01'                         /* months prior to Jul‑24  */
    GROUP BY
        "order_month",
        "product_id"
),
ranked_products AS (
    /* 2.  Rank products inside each month: first by units, then by revenue    */
    SELECT
        mps."order_month",
        mps."product_id",
        mps."total_sales",
        mps."total_revenue",
        p."name"       AS "product_name",
        p."brand"      AS "brand",
        p."category"   AS "category",
        ROW_NUMBER() OVER (
            PARTITION BY mps."order_month"
            ORDER BY mps."total_sales" DESC,
                     mps."total_revenue" DESC
        )              AS "rn"
    FROM monthly_product_sales mps
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS" p
          ON p."id" = mps."product_id"
)
SELECT
    TO_CHAR("order_month", 'YYYY-MM')  AS "month",
    "product_name",
    "brand",
    "category",
    "total_sales",
    ROUND("total_revenue", 2)          AS "total_revenue",
    'Complete'                         AS "order_status"
FROM ranked_products
WHERE "rn" = 1                         /* keep only the monthly top seller    */
ORDER BY "month";