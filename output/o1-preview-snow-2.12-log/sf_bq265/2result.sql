WITH total_order_values AS (
    SELECT o."user_id", o."order_id",
           o."num_of_item" * SUM(oi."sale_price") AS "order_total"
    FROM "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDERS" o
    JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS" oi
        ON o."order_id" = oi."order_id"
    WHERE o."created_at" BETWEEN 1546300800000000 AND 1577836799000000
    GROUP BY o."user_id", o."order_id", o."num_of_item"
),
user_totals AS (
    SELECT t."user_id", SUM(t."order_total") AS "total_order_value", COUNT(DISTINCT t."order_id") AS "order_count"
    FROM total_order_values t
    GROUP BY t."user_id"
)
SELECT u."email" AS "Email_Address",
       ROUND(ut."total_order_value" / ut."order_count", 4) AS "Average_Order_Value"
FROM user_totals ut
JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."USERS" u
    ON ut."user_id" = u."id"
WHERE u."created_at" BETWEEN 1546300800000000 AND 1577836799000000
ORDER BY "Average_Order_Value" DESC NULLS LAST
LIMIT 10;