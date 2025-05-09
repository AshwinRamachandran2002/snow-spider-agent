WITH top_customers AS (
    SELECT c.customer_unique_id, COUNT(*) AS num_delivered_orders
    FROM olist_orders AS o
    JOIN olist_customers AS c ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
    ORDER BY num_delivered_orders DESC
    LIMIT 3
),
customer_info AS (
    SELECT customer_unique_id, MIN(customer_city) AS city, MIN(customer_state) AS state
    FROM olist_customers
    WHERE customer_unique_id IN (SELECT customer_unique_id FROM top_customers)
    GROUP BY customer_unique_id
),
customer_payments AS (
    SELECT c.customer_unique_id, AVG(p.payment_value) AS average_payment_value
    FROM olist_orders AS o
    JOIN olist_customers AS c ON o.customer_id = c.customer_id
    JOIN olist_order_payments AS p ON o.order_id = p.order_id
    WHERE o.order_status = 'delivered' AND c.customer_unique_id IN (SELECT customer_unique_id FROM top_customers)
    GROUP BY c.customer_unique_id
)
SELECT
    tc.customer_unique_id,
    ROUND(cp.average_payment_value, 4) AS average_payment_value,
    ci.city,
    ci.state
FROM top_customers AS tc
JOIN customer_info AS ci ON tc.customer_unique_id = ci.customer_unique_id
JOIN customer_payments AS cp ON tc.customer_unique_id = cp.customer_unique_id;