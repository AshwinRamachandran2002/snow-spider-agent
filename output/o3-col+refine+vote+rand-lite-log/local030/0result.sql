WITH delivered AS (
    SELECT o.order_id,
           c.customer_city AS city
    FROM olist_orders        AS o
    JOIN olist_customers     AS c ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
),
payments_per_order AS (
    SELECT op.order_id,
           SUM(op.payment_value) AS order_payment
    FROM olist_order_payments AS op
    GROUP BY op.order_id
),
city_totals AS (
    SELECT d.city,
           SUM(p.order_payment) AS total_payments,
           COUNT(*)             AS delivered_orders
    FROM delivered          AS d
    JOIN payments_per_order AS p ON p.order_id = d.order_id
    GROUP BY d.city
),
bottom_five AS (
    SELECT *
    FROM city_totals
    ORDER BY total_payments ASC
    LIMIT 5
)
SELECT AVG(total_payments)   AS avg_total_payments,
       AVG(delivered_orders) AS avg_delivered_order_counts
FROM bottom_five;