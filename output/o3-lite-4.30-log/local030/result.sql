WITH city_totals AS (
    SELECT
        c.customer_city,
        COUNT(DISTINCT o.order_id) AS delivered_order_cnt,
        SUM(p.payment_value)      AS total_payments
    FROM olist_orders o
    JOIN olist_customers c       ON o.customer_id = c.customer_id
    JOIN olist_order_payments p  ON o.order_id    = p.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_city
    ORDER BY total_payments ASC, c.customer_city
    LIMIT 5
)
SELECT
    ROUND(AVG(total_payments), 4)      AS avg_total_payment,
    ROUND(AVG(delivered_order_cnt),4)  AS avg_total_delivered_order_count
FROM city_totals;