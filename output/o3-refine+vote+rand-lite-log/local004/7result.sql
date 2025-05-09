WITH order_totals AS (
    SELECT
        order_id,
        SUM(payment_value) AS total_payment
    FROM order_payments
    GROUP BY order_id
),
customer_orders AS (
    SELECT
        o.customer_id,
        o.order_id,
        ot.total_payment,
        o.order_purchase_timestamp
    FROM orders AS o
    JOIN order_totals AS ot ON ot.order_id = o.order_id
),
customer_metrics AS (
    SELECT
        customer_id,
        COUNT(DISTINCT order_id)                                    AS number_of_orders,
        AVG(total_payment)                                          AS avg_payment_per_order,
        MIN(order_purchase_timestamp)                               AS first_purchase_ts,
        MAX(order_purchase_timestamp)                               AS last_purchase_ts
    FROM customer_orders
    GROUP BY customer_id
),
final AS (
    SELECT
        customer_id,
        number_of_orders,
        avg_payment_per_order,
        CASE
            WHEN (julianday(last_purchase_ts) - julianday(first_purchase_ts)) < 7
                 THEN 1.0
            ELSE (julianday(last_purchase_ts) - julianday(first_purchase_ts)) / 7.0
        END                                                        AS lifespan_weeks
    FROM customer_metrics
)
SELECT
    customer_id,
    number_of_orders,
    ROUND(avg_payment_per_order, 4) AS avg_payment_per_order,
    ROUND(lifespan_weeks, 4)       AS lifespan_weeks
FROM final
ORDER BY avg_payment_per_order DESC, customer_id
LIMIT 3;