/*  Monthly top-selling product (by volume, revenue as tie-breaker)
    – considers only orders/items whose status is ‘Complete’
    – ignores products whose brand is NULL
    – restricts to months prior to 2024-07
*/
WITH monthly_product_sales AS (
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP(oi."created_at" / 1000000))                 AS "month",
        p."name"                                                                    AS "product_name",
        p."brand",
        p."category",
        COUNT(*)                                                                    AS "total_sales",
        ROUND(SUM(oi."sale_price"), 2)                                              AS "total_revenue",
        o."status"                                                                  AS "order_status",
        ROW_NUMBER() OVER (
            PARTITION BY DATE_TRUNC('month', TO_TIMESTAMP(oi."created_at" / 1000000))
            ORDER BY COUNT(*) DESC, SUM(oi."sale_price") DESC
        )                                                                           AS "rnk"
    FROM   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  oi
    JOIN   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"       o
           ON o."order_id" = oi."order_id"
    JOIN   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"     p
           ON p."id" = oi."product_id"
    WHERE  o."status"        = 'Complete'
      AND  oi."status"       = 'Complete'
      AND  p."brand"         IS NOT NULL
      AND  DATE_TRUNC('month', TO_TIMESTAMP(oi."created_at" / 1000000)) < '2024-07-01'
    GROUP  BY 1, 2, 3, 4, o."status"
)

SELECT
    "month",
    "product_name",
    "brand",
    "category",
    "total_sales",
    "total_revenue",
    "order_status"
FROM   monthly_product_sales
WHERE  "rnk" = 1
ORDER  BY "month" DESC NULLS LAST;