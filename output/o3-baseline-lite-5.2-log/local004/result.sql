WITH payment_per_order AS (
    SELECT
        order_id,
        SUM(payment_value) AS order_payment
    FROM order_payments
    GROUP BY order_id
),
orders_with_payment AS (
    SELECT
        o.customer_id,
        o.order_purchase_timestamp,
        p.order_payment
    FROM orders AS o
    JOIN payment_per_order AS p
        ON p.order_id = o.order_id
),
customer_metrics AS (
    SELECT
        customer_id,
        COUNT(*) AS number_of_orders,
        AVG(order_payment) AS average_payment_per_order,
        CASE
            WHEN (julianday(MAX(order_purchase_timestamp)) -
                  julianday(MIN(order_purchase_timestamp))) < 7
            THEN 1.0
            ELSE (julianday(MAX(order_purchase_timestamp)) -
                  julianday(MIN(order_purchase_timestamp))) / 7.0
        END AS customer_lifespan_weeks
    FROM orders_with_payment
    GROUP BY customer_id
)
SELECT
    customer_id,
    number_of_orders,
    average_payment_per_order,
    customer_lifespan_weeks
FROM customer_metrics
ORDER BY average_payment_per_order DESC, customer_id
LIMIT 3;