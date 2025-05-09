WITH city_stats AS (
    SELECT
        c.customer_city                             AS city,
        SUM(op.payment_value)                       AS total_payments,
        COUNT(DISTINCT o.order_id)                  AS total_orders
    FROM olist_orders            AS o
    JOIN olist_order_payments    AS op USING (order_id)
    JOIN olist_customers         AS c  ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_city
),
bottom5 AS (
    SELECT *
    FROM city_stats
    ORDER BY total_payments ASC, city ASC
    LIMIT 5
)
SELECT
    ROUND(AVG(total_payments), 4)  AS avg_total_payments,
    ROUND(AVG(total_orders), 4)    AS avg_delivered_order_counts
FROM bottom5;