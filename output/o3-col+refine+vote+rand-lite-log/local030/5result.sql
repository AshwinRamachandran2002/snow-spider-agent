WITH city_payments AS (
    SELECT
        c.customer_city                          AS city,
        SUM(p.payment_value)                     AS total_payment_city,
        COUNT(DISTINCT o.order_id)               AS delivered_orders_city
    FROM   olist_orders         AS o
    JOIN   olist_order_payments AS p ON p.order_id  = o.order_id
    JOIN   olist_customers      AS c ON c.customer_id = o.customer_id
    WHERE  o.order_status = 'delivered'
    GROUP  BY c.customer_city
),
bottom_five AS (
    SELECT *
    FROM   city_payments
    ORDER  BY total_payment_city ASC
    LIMIT  5
)
SELECT
    ROUND(AVG(total_payment_city), 4)      AS avg_of_total_payments,
    ROUND(AVG(delivered_orders_city), 4)   AS avg_of_delivered_order_counts
FROM bottom_five;