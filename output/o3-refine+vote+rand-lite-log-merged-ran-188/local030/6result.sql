WITH delivered_orders AS (
    SELECT 
        o.order_id,
        c.customer_city
    FROM olist_orders AS o
    JOIN olist_customers AS c
         ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
),
city_stats AS (
    SELECT
        d.customer_city                          AS city,
        SUM(p.payment_value)                     AS total_payments,
        COUNT(DISTINCT d.order_id)               AS delivered_orders
    FROM delivered_orders AS d
    JOIN olist_order_payments AS p
         ON d.order_id = p.order_id
    GROUP BY d.customer_city
),
lowest_five AS (
    SELECT
        city,
        total_payments,
        delivered_orders
    FROM city_stats
    ORDER BY total_payments ASC, city ASC
    LIMIT 5
)
SELECT
    ROUND(AVG(total_payments), 4)      AS avg_total_payments,
    ROUND(AVG(delivered_orders), 4)    AS avg_total_delivered_orders
FROM lowest_five;