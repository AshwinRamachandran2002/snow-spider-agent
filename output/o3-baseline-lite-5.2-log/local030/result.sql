WITH city_delivery_stats AS (
    SELECT 
        c.customer_city                               AS city,
        SUM(op.payment_value)                         AS total_payments,
        COUNT(DISTINCT o.order_id)                    AS delivered_order_cnt
    FROM olist_orders           AS o
    JOIN olist_customers        AS c  ON o.customer_id = c.customer_id
    JOIN olist_order_payments   AS op ON o.order_id    = op.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_city
),
lowest_five AS (
    SELECT *
    FROM city_delivery_stats
    ORDER BY total_payments ASC, city ASC
    LIMIT 5
)
SELECT 
    ROUND(AVG(total_payments), 4)      AS avg_total_payments,
    ROUND(AVG(delivered_order_cnt), 4) AS avg_delivered_order_cnt
FROM lowest_five;