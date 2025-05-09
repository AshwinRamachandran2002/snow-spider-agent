WITH order_payment_totals AS (
    /* total amount paid in each order */
    SELECT
        op.order_id,
        SUM(op.payment_value) AS order_payment_total
    FROM order_payments op
    GROUP BY op.order_id
),
customer_orders AS (
    /* every order with its customer, purchase date and total payment */
    SELECT
        o.customer_id,
        o.order_id,
        o.order_purchase_timestamp,
        COALESCE(opt.order_payment_total, 0) AS order_payment_total
    FROM orders o
    LEFT JOIN order_payment_totals opt
           ON opt.order_id = o.order_id
),
customer_stats AS (
    /* aggregate per customer */
    SELECT
        customer_id,
        COUNT(order_id)                         AS num_orders,
        ROUND(AVG(order_payment_total), 4)      AS avg_payment_per_order,
        MIN(order_purchase_timestamp)           AS first_order_date,
        MAX(order_purchase_timestamp)           AS last_order_date
    FROM customer_orders
    GROUP BY customer_id
),
customer_final AS (
    /* compute lifespan in weeks (min‑1 week rule) */
    SELECT
        customer_id,
        num_orders,
        avg_payment_per_order,
        ROUND(
            CASE
                WHEN (julianday(last_order_date) - julianday(first_order_date)) < 7
                     THEN 1.0
                ELSE (julianday(last_order_date) - julianday(first_order_date)) / 7.0
            END, 4)                            AS customer_lifespan_weeks
    FROM customer_stats
)
SELECT
    customer_id,
    num_orders,
    avg_payment_per_order,
    customer_lifespan_weeks
FROM customer_final
ORDER BY avg_payment_per_order DESC,
         customer_id
LIMIT 3;