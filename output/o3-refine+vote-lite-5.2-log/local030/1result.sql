WITH city_stats AS (
    SELECT
        c.customer_city                           AS city,
        SUM(p.payment_value)                      AS total_payments,
        COUNT(DISTINCT o.order_id)                AS order_count
    FROM   olist_orders           o
    JOIN   olist_customers        c ON o.customer_id = c.customer_id
    JOIN   olist_order_payments   p ON o.order_id   = p.order_id
    WHERE  o.order_status = 'delivered'
    GROUP  BY c.customer_city
),
lowest_five AS (
    SELECT
        city,
        total_payments,
        order_count
    FROM   city_stats
    ORDER  BY total_payments ASC, city ASC
    LIMIT  5
)
SELECT
    ROUND(AVG(total_payments), 4) AS avg_total_payments,
    ROUND(AVG(order_count),   4) AS avg_total_order_count
FROM   lowest_five;