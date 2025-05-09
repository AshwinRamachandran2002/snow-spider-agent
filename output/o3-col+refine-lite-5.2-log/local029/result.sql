WITH delivered_orders AS (
    SELECT
        o."order_id",
        c."customer_unique_id",
        c."customer_city",
        c."customer_state"
    FROM "olist_orders"   AS o
    JOIN "olist_customers" AS c
          ON o."customer_id" = c."customer_id"
    WHERE o."order_status" = 'delivered'
),
order_payments AS (
    SELECT
        "order_id",
        SUM("payment_value") AS total_payment
    FROM "olist_order_payments"
    GROUP BY "order_id"
),
customer_stats AS (
    SELECT
        d."customer_unique_id",
        COUNT(*)                    AS delivered_order_cnt,
        AVG(op.total_payment)       AS avg_payment_value,
        MIN(d."customer_city")      AS customer_city,
        MIN(d."customer_state")     AS customer_state
    FROM delivered_orders d
    JOIN order_payments  op
          ON d."order_id" = op."order_id"
    GROUP BY d."customer_unique_id"
),
top3 AS (
    SELECT *
    FROM customer_stats
    ORDER BY delivered_order_cnt DESC, "customer_unique_id"
    LIMIT 3
)
SELECT
    "customer_unique_id",
    delivered_order_cnt,
    ROUND(avg_payment_value, 2) AS avg_payment_value,
    customer_city,
    customer_state
FROM top3
ORDER BY delivered_order_cnt DESC, "customer_unique_id";