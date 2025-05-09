WITH payments AS (
    SELECT
        order_id,
        SUM(payment_value) AS total_payment_value
    FROM olist_order_payments
    GROUP BY order_id
),
delivered AS (
    SELECT
        o.order_id,
        c.customer_unique_id,
        p.total_payment_value,
        c.customer_city,
        c.customer_state
    FROM olist_orders AS o
    JOIN olist_customers AS c
        ON o.customer_id = c.customer_id
    JOIN payments AS p
        ON p.order_id = o.order_id
    WHERE o.order_status = 'delivered'
),
customer_agg AS (
    SELECT
        customer_unique_id,
        COUNT(order_id)          AS delivered_orders,
        AVG(total_payment_value) AS average_payment_value,
        MIN(customer_city)       AS customer_city,
        MIN(customer_state)      AS customer_state
    FROM delivered
    GROUP BY customer_unique_id
)
SELECT
    customer_unique_id,
    ROUND(average_payment_value, 4) AS average_payment_value,
    customer_city,
    customer_state
FROM customer_agg
ORDER BY delivered_orders DESC, customer_unique_id
LIMIT 3;