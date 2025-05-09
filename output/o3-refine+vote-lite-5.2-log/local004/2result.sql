WITH per_order AS (
    SELECT
        o.order_id,
        o.customer_id,
        julianday(o.order_purchase_timestamp)          AS purchase_jd   -- numeric date for maths
    FROM orders AS o
),

-- total amount paid per order (sums every payment component of the order)
order_payment_totals AS (
    SELECT
        op.order_id,
        SUM(op.payment_value)                          AS order_payment_value
    FROM order_payments AS op
    GROUP BY op.order_id
),

-- aggregate the required stats per customer
customer_stats AS (
    SELECT
        po.customer_id,
        COUNT(DISTINCT po.order_id)                                        AS number_of_orders,
        AVG(opt.order_payment_value)                                       AS average_payment_per_order,
        CASE
            WHEN (MAX(po.purchase_jd) - MIN(po.purchase_jd)) < 7
                 THEN 1.0
            ELSE  (MAX(po.purchase_jd) - MIN(po.purchase_jd)) / 7.0
        END                                                               AS customer_lifespan_weeks
    FROM per_order                AS po
    JOIN order_payment_totals     AS opt   ON opt.order_id = po.order_id
    GROUP BY po.customer_id
)

SELECT
    customer_id,
    number_of_orders,
    ROUND(average_payment_per_order, 4)   AS average_payment_per_order,
    ROUND(customer_lifespan_weeks, 4)     AS customer_lifespan_weeks
FROM customer_stats
ORDER BY average_payment_per_order DESC, customer_id
LIMIT 3;