WITH order_payment_totals AS (
    SELECT
        op.order_id,
        SUM(op.payment_value) AS order_payment_total
    FROM order_payments AS op
    GROUP BY op.order_id
),
customer_orders AS (
    SELECT
        o.customer_id,
        o.order_id,
        o.order_purchase_timestamp,
        opt.order_payment_total
    FROM orders AS o
    JOIN order_payment_totals AS opt
          ON opt.order_id = o.order_id
),
customer_stats AS (
    SELECT
        customer_id,
        COUNT(order_id)                                        AS number_of_orders,
        AVG(order_payment_total)                               AS avg_payment_per_order,
        MIN(order_purchase_timestamp)                          AS first_purchase,
        MAX(order_purchase_timestamp)                          AS last_purchase
    FROM customer_orders
    GROUP BY customer_id
),
lifespans AS (
    SELECT
        customer_id,
        number_of_orders,
        avg_payment_per_order,
        CASE
            WHEN ((julianday(last_purchase) - julianday(first_purchase)) / 7.0) < 1 
                 THEN 1.0
            ELSE (julianday(last_purchase) - julianday(first_purchase)) / 7.0
        END                                                  AS customer_lifespan_weeks
    FROM customer_stats
)
SELECT
    customer_id,
    number_of_orders,
    ROUND(avg_payment_per_order, 4)      AS average_payment_per_order,
    ROUND(customer_lifespan_weeks, 4)    AS customer_lifespan_weeks
FROM lifespans
ORDER BY avg_payment_per_order DESC, customer_id
LIMIT 3;