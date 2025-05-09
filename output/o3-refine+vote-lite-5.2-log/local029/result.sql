WITH orders_delivered AS (
    SELECT
        order_id,
        customer_id
    FROM olist_orders
    WHERE order_status = 'delivered'
),
customer_orders AS (
    SELECT
        od.order_id,
        c.customer_unique_id,
        c.customer_city,
        c.customer_state
    FROM orders_delivered od
    JOIN olist_customers c
        ON od.customer_id = c.customer_id
),
payment_totals AS (
    SELECT
        order_id,
        SUM(payment_value) AS total_payment
    FROM olist_order_payments
    GROUP BY order_id
),
customer_stats AS (
    SELECT
        co.customer_unique_id,
        COUNT(DISTINCT co.order_id)                    AS delivered_orders,
        AVG(pt.total_payment)                          AS avg_payment,
        MIN(co.customer_city)  AS customer_city,
        MIN(co.customer_state) AS customer_state
    FROM customer_orders co
    LEFT JOIN payment_totals pt
        ON co.order_id = pt.order_id
    GROUP BY co.customer_unique_id
)
SELECT
    customer_unique_id,
    ROUND(avg_payment, 4) AS average_payment_value,
    customer_city,
    customer_state
FROM customer_stats
ORDER BY delivered_orders DESC, customer_unique_id
LIMIT 3;