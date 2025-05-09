WITH delivered_orders AS (
    SELECT 
        o."order_id",
        o."customer_id"
    FROM "olist_orders" o
    WHERE o."order_status" = 'delivered'
),
order_totals AS (
    SELECT 
        op."order_id",
        SUM(op."payment_value") AS order_total_payment
    FROM "olist_order_payments" op
    GROUP BY op."order_id"
),
orders_with_customers AS (
    SELECT 
        d."order_id",
        c."customer_unique_id",
        c."customer_city",
        c."customer_state"
    FROM delivered_orders d
    JOIN "olist_customers" c
      ON d."customer_id" = c."customer_id"
),
customer_stats AS (
    SELECT
        owc."customer_unique_id",
        COUNT(*)                              AS delivered_orders,
        AVG(ot.order_total_payment)           AS avg_payment_value,
        MIN(owc."customer_city")              AS customer_city,   -- arbitrary choice if multiple addresses
        MIN(owc."customer_state")             AS customer_state
    FROM orders_with_customers owc
    JOIN order_totals ot
      ON owc."order_id" = ot."order_id"
    GROUP BY owc."customer_unique_id"
)
SELECT
    "customer_unique_id",
    delivered_orders,
    ROUND(avg_payment_value, 2) AS avg_payment_value,
    "customer_city",
    "customer_state"
FROM customer_stats
ORDER BY delivered_orders DESC
LIMIT 3;