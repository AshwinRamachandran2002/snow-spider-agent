SELECT 
    AVG(total_city_payment) AS avg_total_payments,
    AVG(delivered_order_count) AS avg_order_counts
FROM (
    SELECT 
        olist_customers.customer_city,
        SUM(olist_order_payments.payment_value) AS total_city_payment,
        COUNT(DISTINCT olist_orders.order_id) AS delivered_order_count
    FROM
        olist_orders
    JOIN 
        olist_order_payments ON olist_orders.order_id = olist_order_payments.order_id
    JOIN 
        olist_customers ON olist_orders.customer_id = olist_customers.customer_id
    WHERE
        olist_orders.order_status = 'delivered'
    GROUP BY
        olist_customers.customer_city
    ORDER BY
        total_city_payment ASC
    LIMIT 5
) AS lowest_cities;