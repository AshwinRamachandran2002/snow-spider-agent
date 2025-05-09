WITH order_payment_total AS (
    /* total payment per order (summing possible split payments) */
    SELECT 
        order_id,
        SUM(payment_value) AS total_payment
    FROM olist_order_payments
    GROUP BY order_id
),
delivered_orders AS (
    /* only delivered orders and their customers */
    SELECT 
        o.order_id,
        c.customer_unique_id,
        c.customer_city,
        c.customer_state
    FROM olist_orders           AS o
    JOIN olist_customers        AS c ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
),
customer_stats AS (
    /* number of delivered orders + average payment value per customer_unique_id */
    SELECT
        d.customer_unique_id,
        COUNT(*)                          AS delivered_order_count,
        AVG(opt.total_payment)            AS avg_payment_value,
        MIN(d.customer_city)              AS city,   -- representative city/state
        MIN(d.customer_state)             AS state
    FROM delivered_orders d
    LEFT JOIN order_payment_total opt ON d.order_id = opt.order_id
    GROUP BY d.customer_unique_id
)
SELECT
    customer_unique_id,
    delivered_order_count,
    ROUND(avg_payment_value, 4) AS average_payment_value,
    city,
    state
FROM customer_stats
ORDER BY delivered_order_count DESC, customer_unique_id
LIMIT 3;