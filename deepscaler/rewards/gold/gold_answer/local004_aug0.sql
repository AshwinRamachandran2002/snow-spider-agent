-- Task: Retrieve the customer_unique_id, number of orders, average payment per order (rounded to two decimal places), and customer lifespan in weeks for the top 3 customers with the highest average payment per order. The number of orders is calculated by counting distinct orders per customer. The customer lifespan is calculated by subtracting the earliest purchase date from the latest purchase date in days, dividing the result by 7 to get weeks, and if the duration is less than 7 days, setting the lifespan to 1 week.

WITH CustomerData AS (
    SELECT
        customer_unique_id,
        COUNT(DISTINCT orders.order_id) AS order_count,
        SUM(payment_value) AS total_payment,
        JULIANDAY(MIN(order_purchase_timestamp)) AS first_order_day,
        JULIANDAY(MAX(order_purchase_timestamp)) AS last_order_day
    FROM customers
        JOIN orders USING (customer_id)
        JOIN order_payments USING (order_id)
    GROUP BY customer_unique_id
)
SELECT
    customer_unique_id,
    order_count AS PF,
    ROUND(total_payment / order_count, 2) AS AOV,
    CASE
        WHEN (last_order_day - first_order_day) < 7 THEN
            1
        ELSE
            (last_order_day - first_order_day) / 7
    END AS ACL
FROM CustomerData
ORDER BY AOV DESC
LIMIT 3