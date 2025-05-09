WITH first_orders AS (
    SELECT o."user_id", MIN(o."created_at") AS "first_order_date"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS" o
    WHERE o."status" != 'Cancelled'
    GROUP BY o."user_id"
),
first_order_ids AS (
    SELECT o."user_id", o."order_id"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS" o
    JOIN first_orders fo ON o."user_id" = fo."user_id" AND o."created_at" = fo."first_order_date"
    WHERE o."status" != 'Cancelled'
),
category_customer_counts AS (
    SELECT p."category", COUNT(DISTINCT o."user_id") AS "customer_count"
    FROM first_order_ids o
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS" oi ON o."order_id" = oi."order_id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS" p ON oi."product_id" = p."id"
    WHERE oi."status" != 'Returned'
    GROUP BY p."category"
),
max_category AS (
    SELECT "category"
    FROM category_customer_counts
    ORDER BY "customer_count" DESC NULLS LAST
    LIMIT 1
),
revenue AS (
    SELECT SUM(oi."sale_price") AS "Revenue"
    FROM first_order_ids o
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS" oi ON o."order_id" = oi."order_id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS" p ON oi."product_id" = p."id"
    WHERE oi."status" != 'Returned' AND p."category" = (SELECT "category" FROM max_category)
)
SELECT (SELECT "category" FROM max_category) AS "Product_Category", ROUND("Revenue", 4) AS "Revenue"
FROM revenue;