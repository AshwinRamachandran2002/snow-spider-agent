WITH first_orders AS (
    SELECT o."user_id", o."order_id", o."created_at"
    FROM "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDERS" o
    WHERE o."status" != 'Cancelled' AND o."created_at" = (
        SELECT MIN(o2."created_at")
        FROM "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDERS" o2
        WHERE o2."user_id" = o."user_id" AND o2."status" != 'Cancelled'
    )
),
first_order_items AS (
    SELECT oi."user_id", oi."order_id", oi."product_id", oi."sale_price", p."category"
    FROM "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS" oi
    JOIN first_orders fo
      ON oi."order_id" = fo."order_id" AND oi."user_id" = fo."user_id"
    JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."PRODUCTS" p
      ON oi."product_id" = p."id"
    WHERE oi."status" NOT IN ('Returned', 'Cancelled')
),
category_customer_counts AS (
    SELECT oi."category", COUNT(DISTINCT oi."user_id") AS "customer_count"
    FROM first_order_items oi
    GROUP BY oi."category"
),
max_category AS (
    SELECT "category"
    FROM category_customer_counts
    ORDER BY "customer_count" DESC NULLS LAST
    LIMIT 1
),
category_revenue AS (
    SELECT "category", SUM("sale_price") AS "Revenue"
    FROM first_order_items
    WHERE "category" = (SELECT "category" FROM max_category)
    GROUP BY "category"
)
SELECT "category" AS "Product_Category", ROUND("Revenue", 4) AS "Revenue"
FROM category_revenue;