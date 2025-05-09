WITH first_orders AS (
    SELECT 
        "user_id",
        "order_id",
        ROW_NUMBER() OVER (PARTITION BY "user_id" ORDER BY "created_at") AS "rn"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"
    WHERE "status" NOT ILIKE '%cancel%'
      AND "returned_at" IS NULL
),
top_category AS (
    SELECT 
        p."category",
        COUNT(DISTINCT f."user_id") AS "num_customers"
    FROM first_orders f
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS" oi
      ON oi."order_id" = f."order_id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS" p
      ON p."id" = oi."product_id"
    WHERE f."rn" = 1
    GROUP BY p."category"
    ORDER BY "num_customers" DESC NULLS LAST
    LIMIT 1
)
SELECT 
    tc."category",
    SUM(oi."sale_price") AS "total_revenue_first_orders"
FROM first_orders f
JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS" oi
  ON oi."order_id" = f."order_id"
JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS" p
  ON p."id" = oi."product_id"
JOIN top_category tc
  ON tc."category" = p."category"
WHERE f."rn" = 1
GROUP BY tc."category";