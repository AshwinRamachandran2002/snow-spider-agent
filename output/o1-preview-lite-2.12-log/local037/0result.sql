SELECT p."product_category_name" AS "Product_Category", COUNT(*) AS "Number_of_Payments"
FROM "olist_order_items" AS oi
JOIN "olist_order_payments" AS op ON oi."order_id" = op."order_id"
JOIN "olist_products" AS p ON oi."product_id" = p."product_id"
WHERE op."payment_installments" = 1
GROUP BY p."product_category_name"
ORDER BY COUNT(*) DESC
LIMIT 3;