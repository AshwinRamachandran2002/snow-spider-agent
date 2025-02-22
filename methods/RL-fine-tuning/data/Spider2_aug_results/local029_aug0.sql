-- Task: Identify the top three customers who have the highest number of orders with status 'delivered'. For each of these customers, provide their average payment value of those delivered orders, along with their city and state.
WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        COUNT(o.order_id) AS Total_Orders_By_Customers,
        AVG(p.payment_value) AS Average_Payment_By_Customer,
        c.customer_city,
        c.customer_state
    FROM olist_customers c
    JOIN olist_orders o ON c.customer_id = o.customer_id
    JOIN olist_order_payments p ON o.order_id = p.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id, c.customer_city, c.customer_state
)

SELECT 
    Average_Payment_By_Customer,
    customer_city,
    customer_state
FROM customer_orders
ORDER BY Total_Orders_By_Customers DESC
LIMIT 3;