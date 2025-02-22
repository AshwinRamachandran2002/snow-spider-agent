-- Task: Could you provide the total number of orders and total payment for each customer? Show up to 100 customers.

SELECT
    customer_unique_id,
    COUNT(DISTINCT orders.order_id) AS order_count,
    SUM(payment_value) AS total_payment
FROM customers
    JOIN orders USING (customer_id)
    JOIN order_payments USING (order_id)
GROUP BY customer_unique_id
LIMIT 100;