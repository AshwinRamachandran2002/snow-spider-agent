SELECT u."email" AS "Email_Address",
       SUM(o."num_of_item" * oi_avg."average_sale_price") / COUNT(DISTINCT o."order_id") AS "Average_Order_Value"
FROM "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."USERS" u
JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDERS" o
    ON u."id" = o."user_id"
JOIN (
    SELECT oi."order_id", AVG(oi."sale_price") AS "average_sale_price"
    FROM "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS" oi
    GROUP BY oi."order_id"
) oi_avg
    ON o."order_id" = oi_avg."order_id"
WHERE TO_TIMESTAMP_NTZ(u."created_at" / 1e6) BETWEEN '2019-01-01' AND '2019-12-31'
  AND TO_TIMESTAMP_NTZ(o."created_at" / 1e6) BETWEEN '2019-01-01' AND '2019-12-31'
GROUP BY u."email"
ORDER BY "Average_Order_Value" DESC NULLS LAST
LIMIT 10;