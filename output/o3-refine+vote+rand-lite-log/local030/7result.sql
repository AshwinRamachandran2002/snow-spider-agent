WITH delivered_orders AS (
    SELECT
        o.order_id,
        o.customer_id
    FROM
        olist_orders AS o
    WHERE
        o.order_status = 'delivered'
),
city_aggregates AS (
    SELECT
        c.customer_city                           AS city,
        SUM(p.payment_value)                      AS total_payment,
        COUNT(DISTINCT o.order_id)                AS order_count
    FROM
        delivered_orders        AS o
        JOIN olist_customers    AS c ON c.customer_id = o.customer_id
        JOIN olist_order_payments AS p ON p.order_id = o.order_id
    GROUP BY
        c.customer_city
),
five_lowest AS (
    SELECT
        city,
        total_payment,
        order_count
    FROM
        city_aggregates
    ORDER BY
        total_payment ASC,
        city ASC          -- tie‑breaker for deterministic ordering
    LIMIT 5
)
SELECT
    ROUND(AVG(total_payment), 4) AS avg_total_payment,
    ROUND(AVG(order_count), 4)   AS avg_order_count
FROM
    five_lowest;