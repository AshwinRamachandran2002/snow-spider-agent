WITH total_payments AS (
    SELECT
        order_id,
        SUM(payment_value) AS total_payment
    FROM olist_order_payments
    GROUP BY order_id
)
SELECT
    c.customer_unique_id,
    COUNT(*)                                AS delivered_orders,
    ROUND(AVG(tp.total_payment), 4)         AS avg_payment_value,
    MIN(c.customer_city)  AS customer_city,
    MIN(c.customer_state) AS customer_state
FROM olist_orders    AS o
JOIN olist_customers AS c  ON c.customer_id = o.customer_id
JOIN total_payments  AS tp ON tp.order_id   = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_unique_id
ORDER BY delivered_orders DESC
LIMIT 3;