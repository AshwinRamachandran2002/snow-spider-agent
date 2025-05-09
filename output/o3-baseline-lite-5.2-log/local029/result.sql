WITH delivered_orders AS (
    SELECT
        o.order_id,
        c.customer_unique_id,
        c.customer_city,
        c.customer_state
    FROM olist_orders AS o
    JOIN olist_customers AS c
        ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
),
order_payments AS (
    SELECT
        order_id,
        SUM(payment_value) AS total_payment
    FROM olist_order_payments
    GROUP BY order_id
),
customer_aggregates AS (
    SELECT
        d.customer_unique_id,
        COUNT(DISTINCT d.order_id)                       AS delivered_orders,
        AVG(op.total_payment)                            AS avg_payment_value,
        MIN(d.customer_city)   AS customer_city,
        MIN(d.customer_state)  AS customer_state
    FROM delivered_orders AS d
    LEFT JOIN order_payments AS op
        ON d.order_id = op.order_id
    GROUP BY d.customer_unique_id
)
SELECT
    customer_unique_id,
    delivered_orders,
    ROUND(avg_payment_value, 4) AS avg_payment_value,
    customer_city,
    customer_state
FROM customer_aggregates
ORDER BY delivered_orders DESC, customer_unique_id
LIMIT 3;