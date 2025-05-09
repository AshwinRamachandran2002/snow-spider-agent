-- Top 3 customers with the highest average payment-per-order,
-- showing number of orders, average payment and lifespan (in weeks)
SELECT
    stats."customer_id",
    stats."num_orders",
    ROUND(stats."avg_payment_per_order", 2) AS "avg_payment_per_order",
    ROUND(
        CASE
            WHEN lifespan."lifespan_days" / 7.0 < 1 THEN 1.0
            ELSE lifespan."lifespan_days" / 7.0
        END, 2
    ) AS "lifespan_weeks"
FROM (
    -- per-customer order count and average payment
    SELECT
        o."customer_id",
        COUNT(DISTINCT o."order_id")               AS "num_orders",
        AVG(pay."total_payment")                   AS "avg_payment_per_order"
    FROM "orders" AS o
    JOIN (
        -- total payment per order
        SELECT
            "order_id",
            SUM("payment_value") AS "total_payment"
        FROM "order_payments"
        GROUP BY "order_id"
    ) AS pay
    ON o."order_id" = pay."order_id"
    GROUP BY o."customer_id"
) AS stats
JOIN (
    -- lifespan in days for each customer
    SELECT
        "customer_id",
        JULIANDAY(MAX(DATE("order_purchase_timestamp"))) -
        JULIANDAY(MIN(DATE("order_purchase_timestamp"))) AS "lifespan_days"
    FROM "orders"
    GROUP BY "customer_id"
) AS lifespan
ON stats."customer_id" = lifespan."customer_id"
ORDER BY stats."avg_payment_per_order" DESC
LIMIT 3;