WITH first_valid_orders AS (
    SELECT
        FIRST_VALUE(o."order_id") OVER (PARTITION BY o."user_id" ORDER BY o."created_at") AS first_order_id,
        o."user_id"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS" o
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS" oi
      ON o."order_id" = oi."order_id"
    WHERE o."status" <> 'Cancelled'
      AND oi."status" NOT IN ('Returned', 'Cancelled')
      AND oi."returned_at" IS NULL
), first_order_categories AS (
    SELECT
        fvo."user_id",
        p."category"
    FROM first_valid_orders fvo
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS" oi
      ON fvo.first_order_id = oi."order_id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS" p
      ON oi."product_id" = p."id"
), top_category AS (
    SELECT
        "category",
        COUNT(DISTINCT "user_id") AS customer_cnt,
        ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT "user_id") DESC, "category" ASC) AS rn
    FROM first_order_categories
    GROUP BY "category"
)
SELECT
    p."category"                          AS product_category,
    ROUND(SUM(oi."sale_price"), 4)        AS total_revenue
FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS" oi
JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"     p  ON oi."product_id" = p."id"
JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"       o  ON oi."order_id"  = o."order_id"
JOIN top_category                                       tc ON p."category"   = tc."category"
WHERE tc.rn = 1
  AND o."status" <> 'Cancelled'
  AND oi."status" NOT IN ('Returned', 'Cancelled')
  AND oi."returned_at" IS NULL
GROUP BY p."category";