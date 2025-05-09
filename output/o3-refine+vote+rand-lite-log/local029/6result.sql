WITH delivered_orders AS (
    SELECT  o.order_id,
            c.customer_unique_id,
            c.customer_city,
            c.customer_state
    FROM   olist_orders  AS o
    JOIN   olist_customers AS c
           ON o.customer_id = c.customer_id
    WHERE  o.order_status = 'delivered'
),
order_payments AS (
    SELECT  order_id,
            SUM(payment_value) AS total_payment           -- total paid for each order
    FROM    olist_order_payments
    GROUP BY order_id
),
customer_agg AS (
    SELECT  d.customer_unique_id,
            COUNT(DISTINCT d.order_id)                AS delivered_orders_cnt,
            AVG(op.total_payment)                     AS avg_payment_value,
            MIN(d.customer_city)                      AS customer_city,
            MIN(d.customer_state)                     AS customer_state
    FROM    delivered_orders d
    LEFT JOIN order_payments op
           ON d.order_id = op.order_id
    GROUP BY d.customer_unique_id
)
SELECT  customer_unique_id,
        ROUND(avg_payment_value,4)   AS avg_payment_value,
        customer_city,
        customer_state
FROM    customer_agg
ORDER BY delivered_orders_cnt DESC,
         customer_unique_id          -- tie‑breaker
LIMIT 3;