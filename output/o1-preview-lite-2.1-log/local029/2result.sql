WITH top_customers AS (
    SELECT c.customer_unique_id, COUNT(o.order_id) AS delivered_orders
    FROM olist_customers c
    JOIN olist_orders o ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
    ORDER BY delivered_orders DESC
    LIMIT 3
)
SELECT 
    c.customer_unique_id, 
    ROUND(AVG(p.payment_value), 4) AS average_payment_value, 
    c.customer_city, 
    c.customer_state
FROM olist_customers c
JOIN olist_orders o ON c.customer_id = o.customer_id
JOIN olist_order_payments p ON o.order_id = p.order_id
WHERE 
    o.order_status = 'delivered' 
    AND c.customer_unique_id IN (SELECT customer_unique_id FROM top_customers)
GROUP BY c.customer_unique_id, c.customer_city, c.customer_state;