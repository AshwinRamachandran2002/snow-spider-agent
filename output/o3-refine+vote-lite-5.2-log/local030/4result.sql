WITH delivered_orders AS (
    SELECT
        o.order_id,
        c.customer_city AS city
    FROM
        olist_orders AS o
        JOIN olist_customers AS c ON c.customer_id = o.customer_id
    WHERE
        o.order_status = 'delivered'
),
city_totals AS (
    SELECT
        d.city,
        SUM(p.payment_value)              AS total_payment,
        COUNT(DISTINCT d.order_id)        AS order_count
    FROM
        delivered_orders AS d
        JOIN olist_order_payments AS p ON p.order_id = d.order_id
    GROUP BY
        d.city
),
lowest_five AS (
    SELECT
        city,
        total_payment,
        order_count
    FROM
        city_totals
    ORDER BY
        total_payment ASC,
        city ASC
    LIMIT 5
)
SELECT
    ROUND(AVG(total_payment), 4) AS average_total_payment,
    ROUND(AVG(order_count), 4)   AS average_order_count
FROM
    lowest_five;