WITH total_payments AS (
    /* total paid for each order */
    SELECT 
        o.order_id,
        o.customer_id,
        SUM(p.payment_value) AS order_payment
    FROM orders AS o
    JOIN order_payments AS p USING (order_id)
    GROUP BY o.order_id
),
customer_payments AS (
    /* orders and average payment per customer */
    SELECT
        customer_id,
        COUNT(*)           AS order_count,
        AVG(order_payment) AS average_payment_per_order
    FROM total_payments
    GROUP BY customer_id
),
customer_lifespan AS (
    /* lifespan in weeks (minimum 1.0) */
    SELECT
        customer_id,
        CASE
            WHEN (JULIANDAY(MAX(order_purchase_timestamp)) -
                  JULIANDAY(MIN(order_purchase_timestamp))) < 7
            THEN 1.0
            ELSE (JULIANDAY(MAX(order_purchase_timestamp)) -
                  JULIANDAY(MIN(order_purchase_timestamp))) / 7.0
        END AS customer_lifespan_weeks
    FROM orders
    GROUP BY customer_id
)
SELECT
    cp.customer_id,
    cp.order_count,
    printf('%.4f', cp.average_payment_per_order) AS average_payment_per_order,
    printf('%.4f', cl.customer_lifespan_weeks)   AS customer_lifespan_weeks
FROM customer_payments AS cp
JOIN customer_lifespan AS cl USING (customer_id)
ORDER BY cp.average_payment_per_order DESC, cp.customer_id
LIMIT 3;