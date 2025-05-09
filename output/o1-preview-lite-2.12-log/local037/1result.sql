SELECT p.product_category_name AS Product_Category,
       COUNT(*) AS Number_of_Payments
FROM olist_products p
JOIN olist_order_items oi ON p.product_id = oi.product_id
JOIN (
    SELECT order_id
    FROM olist_order_payments
    GROUP BY order_id
    HAVING COUNT(DISTINCT payment_type) = 1
) op ON oi.order_id = op.order_id
GROUP BY p.product_category_name
ORDER BY Number_of_Payments DESC
LIMIT 3;