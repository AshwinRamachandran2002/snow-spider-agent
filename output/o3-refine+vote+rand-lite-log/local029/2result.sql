WITH delivered_orders AS (
    SELECT
        c.customer_unique_id,
        COUNT(o.order_id) AS num_delivered_orders
    FROM olist_orders            AS o
    JOIN olist_customers         AS c  ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),

top_customers AS (
    SELECT
        customer_unique_id,
        num_delivered_orders
    FROM delivered_orders
    ORDER BY num_delivered_orders DESC, customer_unique_id
    LIMIT 3
),

payments_by_customer AS (
    SELECT
        c.customer_unique_id,
        AVG(p.payment_value) AS avg_payment_value
    FROM olist_orders           AS o
    JOIN olist_customers        AS c ON o.customer_id = c.customer_id
    JOIN olist_order_payments   AS p ON o.order_id = p.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)

SELECT
    tc.customer_unique_id,
    pb.avg_payment_value  AS average_payment_value,
    MIN(cu.customer_city) AS customer_city,
    MIN(cu.customer_state) AS customer_state
FROM top_customers        AS tc
JOIN payments_by_customer AS pb  ON pb.customer_unique_id = tc.customer_unique_id
JOIN olist_customers      AS cu  ON cu.customer_unique_id = tc.customer_unique_id
GROUP BY
    tc.customer_unique_id,
    pb.avg_payment_value,
    tc.num_delivered_orders
ORDER BY
    tc.num_delivered_orders DESC,
    tc.customer_unique_id;