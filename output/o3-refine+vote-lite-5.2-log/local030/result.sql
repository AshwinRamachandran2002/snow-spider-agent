WITH delivered_orders AS (
    SELECT 
        o.order_id,
        o.customer_id
    FROM olist_orders AS o
    WHERE o.order_status = 'delivered'
),
order_payments_sum AS (
    SELECT 
        op.order_id,
        SUM(op.payment_value) AS order_payment
    FROM olist_order_payments AS op
    GROUP BY op.order_id
),
city_aggregates AS (
    SELECT
        c.customer_city                        AS city,
        SUM(ops.order_payment)                 AS total_payment,
        COUNT(*)                               AS delivered_order_count
    FROM delivered_orders      AS d
    JOIN olist_customers       AS c   ON c.customer_id = d.customer_id
    JOIN order_payments_sum    AS ops ON ops.order_id  = d.order_id
    GROUP BY c.customer_city
),
lowest_five_cities AS (
    SELECT *
    FROM city_aggregates
    ORDER BY total_payment ASC, city
    LIMIT 5
)
SELECT
    AVG(total_payment)          AS avg_total_payment,
    AVG(delivered_order_count)  AS avg_delivered_order_count
FROM lowest_five_cities;