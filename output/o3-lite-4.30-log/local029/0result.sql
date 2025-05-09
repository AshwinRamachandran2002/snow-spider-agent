WITH delivered_orders AS (
    SELECT 
        order_id,
        customer_id
    FROM olist_orders
    WHERE order_status = 'delivered'
),
order_totals AS (
    SELECT 
        order_id,
        SUM(payment_value) AS total_payment
    FROM olist_order_payments
    GROUP BY order_id
),
customer_aggregates AS (
    SELECT
        c.customer_unique_id,
        COUNT(d.order_id)     AS delivered_orders,
        AVG(ot.total_payment) AS avg_payment,
        MAX(c.customer_city)  AS customer_city,
        MAX(c.customer_state) AS customer_state
    FROM delivered_orders d
    JOIN olist_customers c ON d.customer_id = c.customer_id
    JOIN order_totals  ot ON d.order_id     = ot.order_id
    GROUP BY c.customer_unique_id
)
SELECT
    customer_unique_id,
    printf('%.4f', avg_payment) AS average_payment_value,
    customer_city,
    customer_state
FROM customer_aggregates
ORDER BY delivered_orders DESC, customer_unique_id
LIMIT 3;