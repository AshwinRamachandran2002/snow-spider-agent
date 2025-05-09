WITH delivered_orders AS (
    SELECT
        o.order_id,
        c.customer_city
    FROM
        olist_orders AS o
        JOIN olist_customers AS c ON o.customer_id = c.customer_id
    WHERE
        o.order_status = 'delivered'
),
order_payments_sum AS (
    SELECT
        order_id,
        SUM(payment_value) AS order_payment
    FROM
        olist_order_payments
    GROUP BY
        order_id
),
city_stats AS (
    SELECT
        d.customer_city               AS city,
        SUM(p.order_payment)          AS total_payment,
        COUNT(DISTINCT d.order_id)    AS order_count
    FROM
        delivered_orders AS d
        JOIN order_payments_sum AS p ON d.order_id = p.order_id
    GROUP BY
        d.customer_city
),
lowest_cities AS (
    SELECT
        city,
        total_payment,
        order_count
    FROM
        city_stats
    ORDER BY
        total_payment ASC,
        city ASC
    LIMIT 5
)
SELECT
    ROUND(AVG(total_payment), 4)  AS avg_total_payment,
    ROUND(AVG(order_count), 4)    AS avg_order_count
FROM
    lowest_cities;