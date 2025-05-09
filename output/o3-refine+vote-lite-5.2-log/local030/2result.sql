WITH delivered_orders AS (
    SELECT
        o.order_id,
        c.customer_city
    FROM olist_orders AS o
    JOIN olist_customers AS c
      ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
),
payments_per_order AS (
    SELECT
        order_id,
        SUM(payment_value) AS order_payment
    FROM olist_order_payments
    GROUP BY order_id
),
city_stats AS (
    SELECT
        d.customer_city AS city,
        SUM(p.order_payment) AS total_payments,
        COUNT(*)            AS order_count
    FROM delivered_orders AS d
    JOIN payments_per_order AS p
      ON d.order_id = p.order_id
    GROUP BY d.customer_city
),
lowest_five AS (
    SELECT
        *
    FROM city_stats
    ORDER BY total_payments ASC, city ASC
    LIMIT 5
)
SELECT
    ROUND(AVG(total_payments), 4) AS avg_total_payments,
    ROUND(AVG(order_count), 4)    AS avg_order_count
FROM lowest_five;