WITH delivered_orders AS (
    SELECT 
        o.order_id,
        o.customer_id
    FROM olist_orders AS o
    WHERE o.order_status = 'delivered'
),
order_payments AS (
    SELECT
        op.order_id,
        SUM(op.payment_value) AS total_payment
    FROM olist_order_payments AS op
    GROUP BY op.order_id
),
cust_orders AS (
    SELECT
        d.order_id,
        c.customer_unique_id,
        c.customer_city,
        c.customer_state
    FROM delivered_orders AS d
    JOIN olist_customers AS c
        ON c.customer_id = d.customer_id
),
cust_order_pay AS (
    SELECT
        co.customer_unique_id,
        co.customer_city,
        co.customer_state,
        op.total_payment
    FROM cust_orders AS co
    JOIN order_payments AS op
        ON op.order_id = co.order_id
),
agg AS (
    SELECT
        customer_unique_id,
        COUNT(*)                      AS delivered_orders_count,
        AVG(total_payment)            AS avg_payment_value,
        MIN(customer_city)            AS customer_city,
        MIN(customer_state)           AS customer_state
    FROM cust_order_pay
    GROUP BY customer_unique_id
)
SELECT
    customer_unique_id,
    delivered_orders_count,
    ROUND(avg_payment_value, 4) AS avg_payment_value,
    customer_city,
    customer_state
FROM agg
ORDER BY delivered_orders_count DESC,
         customer_unique_id
LIMIT 3;