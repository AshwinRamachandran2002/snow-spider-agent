WITH payments_per_order AS (
    SELECT 
        order_id,
        SUM(payment_value) AS total_payment
    FROM order_payments
    GROUP BY order_id
),
customer_order_payments AS (
    SELECT 
        o.customer_id,
        o.order_id,
        o.order_purchase_timestamp,
        p.total_payment
    FROM orders AS o
    JOIN payments_per_order AS p
      ON o.order_id = p.order_id
),
customer_stats AS (
    SELECT
        customer_id,
        COUNT(order_id)                                   AS num_orders,
        AVG(total_payment)                                AS avg_payment_per_order,
        CASE
            WHEN (julianday(MAX(order_purchase_timestamp)) -
                  julianday(MIN(order_purchase_timestamp))) < 7
                 THEN 1.0
            ELSE  (julianday(MAX(order_purchase_timestamp)) -
                    julianday(MIN(order_purchase_timestamp))) / 7.0
        END                                               AS lifespan_weeks
    FROM customer_order_payments
    GROUP BY customer_id
)
SELECT
    customer_id,
    num_orders,
    ROUND(avg_payment_per_order, 4) AS avg_payment_per_order,
    ROUND(lifespan_weeks, 4)        AS lifespan_weeks
FROM customer_stats
ORDER BY avg_payment_per_order DESC, customer_id
LIMIT 3;