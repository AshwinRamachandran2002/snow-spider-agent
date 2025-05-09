SELECT u."email", ROUND(AVG(order_totals."order_total"), 4) AS "average_order_value"
FROM (
    SELECT oi."order_id", SUM(oi."sale_price") AS "order_total"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS" oi
    GROUP BY oi."order_id"
) order_totals
JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS" o ON order_totals."order_id" = o."order_id"
JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS" u ON o."user_id" = u."id"
WHERE u."created_at" BETWEEN 1546300800000000 AND 1577836799000000
  AND o."created_at" BETWEEN 1546300800000000 AND 1577836799000000
GROUP BY u."email"
ORDER BY "average_order_value" DESC NULLS LAST
LIMIT 10;