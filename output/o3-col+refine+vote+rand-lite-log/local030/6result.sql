SELECT 
    ROUND(AVG(five.total_payments), 4)        AS avg_of_five_cities_total_payments,
    ROUND(AVG(five.delivered_order_count), 4) AS avg_of_five_cities_order_counts
FROM (
    SELECT 
        c.customer_city                      AS city,
        SUM(op.payment_value)                AS total_payments,
        COUNT(DISTINCT o.order_id)           AS delivered_order_count
    FROM olist_orders AS o
    JOIN olist_order_payments AS op ON o.order_id   = op.order_id
    JOIN olist_customers      AS c  ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_city
    ORDER BY total_payments ASC
    LIMIT 5
) AS five;