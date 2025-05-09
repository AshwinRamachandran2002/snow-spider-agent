WITH order_payment_total AS (
    -- total payment value of every order
    SELECT 
        "order_id",
        SUM("payment_value") AS order_payment_value
    FROM "order_payments"
    GROUP BY "order_id"
),
orders_with_payment AS (
    -- add customer and purchase moment to every paid order
    SELECT
        o."order_id",
        o."customer_id",
        o."order_purchase_timestamp",
        opt.order_payment_value
    FROM "orders"  AS o
    JOIN order_payment_total AS opt
          ON o."order_id" = opt."order_id"
),
customer_stats AS (
    -- basic stats per customer
    SELECT
        "customer_id",
        COUNT(DISTINCT "order_id")                    AS number_of_orders,
        AVG(order_payment_value)                      AS avg_payment_per_order,
        MIN("order_purchase_timestamp")               AS first_purchase,
        MAX("order_purchase_timestamp")               AS last_purchase,
        julianday(MAX("order_purchase_timestamp"))
          - julianday(MIN("order_purchase_timestamp")) AS days_diff
    FROM orders_with_payment
    GROUP BY "customer_id"
),
customer_lifespan AS (
    -- translate the time‑span from days to weeks,
    -- forcing at least one week when the span is < 7 days
    SELECT
        "customer_id",
        number_of_orders,
        avg_payment_per_order,
        CASE
            WHEN days_diff < 7 THEN 1.0
            ELSE days_diff / 7.0
        END AS lifespan_weeks
    FROM customer_stats
)
SELECT
    "customer_id",
    number_of_orders,
    ROUND(avg_payment_per_order, 4) AS avg_payment_per_order,
    ROUND(lifespan_weeks, 4)        AS lifespan_weeks
FROM customer_lifespan
ORDER BY avg_payment_per_order DESC, "customer_id"
LIMIT 3;