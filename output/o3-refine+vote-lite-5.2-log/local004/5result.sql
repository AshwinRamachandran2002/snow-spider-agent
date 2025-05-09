WITH order_payments_sum AS (
    SELECT 
        order_id,
        SUM(payment_value) AS order_payment
    FROM order_payments
    GROUP BY order_id
),
orders_with_payment AS (
    SELECT
        o.order_id,
        o.customer_id,
        o.order_purchase_timestamp,
        p.order_payment
    FROM orders AS o
    JOIN order_payments_sum AS p
        ON o.order_id = p.order_id
),
customer_base AS (
    SELECT
        customer_id,
        COUNT(*)                      AS num_orders,
        SUM(order_payment)            AS total_payment,
        SUM(order_payment) * 1.0
            / COUNT(*)               AS avg_payment_per_order,
        MIN(order_purchase_timestamp) AS first_purchase,
        MAX(order_purchase_timestamp) AS last_purchase
    FROM orders_with_payment
    GROUP BY customer_id
),
customer_stats AS (
    SELECT
        customer_id,
        num_orders,
        ROUND(avg_payment_per_order, 4) AS avg_payment_per_order,
        ROUND(
            CASE
                WHEN (julianday(last_purchase) - julianday(first_purchase)) < 7
                     THEN 1.0
                ELSE (julianday(last_purchase) - julianday(first_purchase)) / 7
            END, 4
        ) AS customer_lifespan_weeks
    FROM customer_base
)
SELECT
    customer_id,
    num_orders          AS number_of_orders,
    avg_payment_per_order,
    customer_lifespan_weeks
FROM customer_stats
ORDER BY avg_payment_per_order DESC, customer_id
LIMIT 3;