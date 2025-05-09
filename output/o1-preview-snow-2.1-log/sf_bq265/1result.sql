SELECT U."email", ROUND(AVG(OI."total_order_value"), 4) AS "Average_Order_Value"
FROM (
    SELECT "order_id", SUM("sale_price") AS "total_order_value"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS
    GROUP BY "order_id"
) OI
JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS O ON OI."order_id" = O."order_id"
JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS U ON O."user_id" = U."id"
WHERE YEAR(TO_TIMESTAMP(U."created_at" / 1000000)) = 2019
  AND YEAR(TO_TIMESTAMP(O."created_at" / 1000000)) = 2019
GROUP BY U."email"
ORDER BY "Average_Order_Value" DESC NULLS LAST
LIMIT 10;