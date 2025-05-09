WITH
-- total payment made in each order
order_totals AS (
    SELECT
        order_id,
        SUM(payment_value) AS total_payment
    FROM order_payments
    GROUP BY order_id
),

-- orders linked with their customers and total payments
customer_orders AS (
    SELECT
        o.customer_id,
        o.order_id,
        ot.total_payment,
        o.order_purchase_timestamp
    FROM orders o
    JOIN order_totals ot ON ot.order_id = o.order_id
),

-- basic stats per customer
customer_stats AS (
    SELECT
        customer_id,
        COUNT(DISTINCT order_id)                           AS number_of_orders,
        AVG(total_payment)                                 AS avg_payment_per_order,
        MIN(order_purchase_timestamp)                      AS first_purchase,
        MAX(order_purchase_timestamp)                      AS last_purchase
    FROM customer_orders
    GROUP BY customer_id
),

-- add lifespan in weeks, enforcing the minimum of 1 week
lifespans AS (
    SELECT
        customer_id,
        number_of_orders,
        avg_payment_per_order,
        CASE
            WHEN (julianday(last_purchase) - julianday(first_purchase)) < 7
                 THEN 1.0
            ELSE  (julianday(last_purchase) - julianday(first_purchase)) / 7.0
        END                                                AS lifespan_weeks
    FROM customer_stats
)

SELECT
    customer_id,
    number_of_orders,
    ROUND(avg_payment_per_order, 4)  AS avg_payment_per_order,
    ROUND(lifespan_weeks, 4)         AS customer_lifespan_weeks
FROM lifespans
ORDER BY avg_payment_per_order DESC, customer_id
LIMIT 3;