WITH delivered_orders AS (
    SELECT
        order_id,
        customer_id
    FROM olist_orders
    WHERE order_status = 'delivered'
),
order_payment_totals AS (
    SELECT
        order_id,
        SUM(payment_value) AS total_payment
    FROM olist_order_payments
    GROUP BY order_id
),
customer_delivered_orders AS (
    SELECT
        d.order_id,
        c.customer_unique_id,
        c.customer_city,
        c.customer_state
    FROM delivered_orders d
    JOIN olist_customers c
      ON d.customer_id = c.customer_id
),
customer_payments AS (
    SELECT
        cdo.customer_unique_id,
        cdo.customer_city,
        cdo.customer_state,
        opt.total_payment
    FROM customer_delivered_orders cdo
    LEFT JOIN order_payment_totals opt
      ON cdo.order_id = opt.order_id
)
SELECT
    cp.customer_unique_id,
    ROUND(AVG(cp.total_payment), 4) AS average_payment_value,
    MIN(cp.customer_city)  AS customer_city,
    MIN(cp.customer_state) AS customer_state
FROM customer_payments cp
GROUP BY cp.customer_unique_id
ORDER BY COUNT(*) DESC, cp.customer_unique_id
LIMIT 3;