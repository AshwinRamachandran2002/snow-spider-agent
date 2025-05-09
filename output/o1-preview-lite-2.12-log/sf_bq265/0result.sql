WITH order_totals AS (
    SELECT o."order_id", o."user_id", SUM(oi."sale_price") AS "order_total_value"
    FROM "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDERS" o
    JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS" oi
      ON o."order_id" = oi."order_id"
    WHERE YEAR(TO_TIMESTAMP(o."created_at" / 1000000)) = 2019
    GROUP BY o."order_id", o."user_id"
)
SELECT u."email" AS "Email_Address",
       ROUND(SUM(order_totals."order_total_value") / COUNT(order_totals."order_id"), 4) AS "Average_Order_Value"
FROM "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."USERS" u
JOIN order_totals
  ON u."id" = order_totals."user_id"
WHERE YEAR(TO_TIMESTAMP(u."created_at" / 1000000)) = 2019
GROUP BY u."email"
ORDER BY "Average_Order_Value" DESC NULLS LAST
LIMIT 10;