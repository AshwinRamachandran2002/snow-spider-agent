WITH city_stats AS (
    SELECT
        c.customer_city                       AS city,
        COUNT(DISTINCT o.order_id)            AS delivered_orders,
        SUM(p.payment_value)                  AS city_total_payments
    FROM olist_orders            AS o
    JOIN olist_order_payments    AS p ON o.order_id   = p.order_id
    JOIN olist_customers         AS c ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_city
),
five_lowest AS (
    SELECT
        city,
        delivered_orders,
        city_total_payments
    FROM city_stats
    ORDER BY city_total_payments ASC
    LIMIT 5
)
SELECT
    ROUND(AVG(city_total_payments), 4) AS avg_total_payments,
    ROUND(AVG(delivered_orders), 4)    AS avg_delivered_orders
FROM five_lowest;