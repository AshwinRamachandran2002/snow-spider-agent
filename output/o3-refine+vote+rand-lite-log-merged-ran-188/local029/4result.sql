WITH delivered_payments AS (
    /* one row per delivered order with its total paid value */
    SELECT  o.order_id,
            c.customer_unique_id,
            SUM(p.payment_value)         AS order_payment_total
    FROM    olist_orders           AS o
    JOIN    olist_customers        AS c  ON c.customer_id = o.customer_id
    JOIN    olist_order_payments   AS p  ON p.order_id     = o.order_id
    WHERE   o.order_status = 'delivered'
    GROUP BY o.order_id, c.customer_unique_id
),
customer_stats AS (
    /* aggregate the delivered orders per customer_unique_id */
    SELECT  customer_unique_id,
            COUNT(*)                       AS delivered_orders_cnt,
            AVG(order_payment_total)       AS avg_payment_value
    FROM    delivered_payments
    GROUP BY customer_unique_id
),
top3 AS (
    /* take the three customers with most delivered orders */
    SELECT  customer_unique_id
    FROM    customer_stats
    ORDER BY delivered_orders_cnt DESC, customer_unique_id
    LIMIT 3
)
SELECT  t.customer_unique_id,
        ROUND(cs.avg_payment_value,4)        AS avg_payment_value,
        MIN(c.customer_city)  AS city,
        MIN(c.customer_state) AS state
FROM    top3                AS t
JOIN    customer_stats       AS cs ON cs.customer_unique_id = t.customer_unique_id
JOIN    olist_customers      AS c  ON c.customer_unique_id  = t.customer_unique_id
GROUP BY t.customer_unique_id;