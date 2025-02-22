-- Task: Calculate the average sales per order for each customer, considering only 'delivered' orders. Use the customer unique identifier. Limit the results to the first 100 customers.

SELECT customer_unique_id,
       SUM(price) / COUNT(DISTINCT order_id) AS avg_sales_per_order
FROM orders
    JOIN order_items USING (order_id)
    JOIN customers USING (customer_id)
WHERE order_status = 'delivered'
GROUP BY customer_unique_id
LIMIT 100;