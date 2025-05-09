SELECT U."email", ROUND(AVG(OrderTotals."order_total_value"), 4) AS "Average_Order_Value"
FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS U
JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS O ON U."id" = O."user_id"
JOIN (
  SELECT "order_id", SUM("sale_price") AS "order_total_value"
  FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS
  GROUP BY "order_id"
) AS OrderTotals ON O."order_id" = OrderTotals."order_id"
WHERE YEAR(TO_TIMESTAMP(U."created_at" / 1000000)) = 2019
  AND YEAR(TO_TIMESTAMP(O."created_at" / 1000000)) = 2019
GROUP BY U."email"
ORDER BY "Average_Order_Value" DESC NULLS LAST
LIMIT 10;