WITH delivered_orders AS (
    SELECT
        o.order_id,
        o.customer_id
    FROM
        olist_orders AS o
    WHERE
        o.order_status = 'delivered'
),
order_payments AS (
    SELECT
        op.order_id,
        SUM(op.payment_value) AS total_payment
    FROM
        olist_order_payments AS op
    GROUP BY
        op.order_id
),
delivered_orders_payments AS (
    SELECT
        d.customer_id,
        d.order_id,
        COALESCE(p.total_payment, 0) AS total_payment
    FROM
        delivered_orders AS d
        LEFT JOIN order_payments AS p USING (order_id)
),
customer_aggregates AS (
    SELECT
        c.customer_unique_id,
        COUNT(dop.order_id)                       AS delivered_order_count,
        AVG(dop.total_payment)                    AS avg_payment_value,
        MIN(c.customer_city)  AS customer_city,
        MIN(c.customer_state) AS customer_state
    FROM
        delivered_orders_payments AS dop
        JOIN olist_customers      AS c ON dop.customer_id = c.customer_id
    GROUP BY
        c.customer_unique_id
)
SELECT
    customer_unique_id,
    ROUND(avg_payment_value, 4) AS avg_payment_value,
    customer_city,
    customer_state
FROM
    customer_aggregates
ORDER BY
    delivered_order_count DESC,
    customer_unique_id ASC
LIMIT 3;