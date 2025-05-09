WITH delivered_orders AS (
    SELECT
        o."order_id",
        c."customer_unique_id",
        c."customer_city",
        c."customer_state"
    FROM "olist_orders"   o
    JOIN "olist_customers" c ON c."customer_id" = o."customer_id"
    WHERE o."order_status" = 'delivered'
),
order_counts AS (
    SELECT
        "customer_unique_id",
        COUNT(*) AS delivered_order_cnt
    FROM delivered_orders
    GROUP BY "customer_unique_id"
),
avg_payments AS (
    SELECT
        d."customer_unique_id",
        ROUND(AVG(p."payment_value"), 4) AS average_payment_value,
        MIN(d."customer_city")  AS customer_city,
        MIN(d."customer_state") AS customer_state
    FROM delivered_orders d
    JOIN "olist_order_payments" p ON p."order_id" = d."order_id"
    GROUP BY d."customer_unique_id"
)
SELECT
    a."customer_unique_id",
    a.average_payment_value,
    a.customer_city,
    a.customer_state
FROM order_counts  oc
JOIN avg_payments a ON a."customer_unique_id" = oc."customer_unique_id"
ORDER BY oc.delivered_order_cnt DESC, a."customer_unique_id"
LIMIT 3;