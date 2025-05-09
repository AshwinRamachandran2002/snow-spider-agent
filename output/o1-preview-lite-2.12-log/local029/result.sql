SELECT
    cs.customer_unique_id,
    ROUND(cs.average_payment_value, 4) AS average_payment_value,
    cs.customer_city,
    cs.customer_state
FROM
    (
        SELECT
            c.customer_unique_id,
            COUNT(o.order_id) AS delivered_orders,
            AVG(p.payment_value) AS average_payment_value,
            c.customer_city,
            c.customer_state
        FROM
            olist_orders AS o
        JOIN
            olist_order_payments AS p ON o.order_id = p.order_id
        JOIN
            olist_customers AS c ON o.customer_id = c.customer_id
        WHERE
            o.order_status = 'delivered'
        GROUP BY
            c.customer_unique_id
        ORDER BY
            delivered_orders DESC
        LIMIT 3
    ) AS cs;