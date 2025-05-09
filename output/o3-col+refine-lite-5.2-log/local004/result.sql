WITH customer_stats AS (
    SELECT
        o."customer_id",
        COUNT(DISTINCT o."order_id")                       AS "number_of_orders",
        SUM(op."payment_value")                            AS "total_paid",
        MIN(o."order_purchase_timestamp")                  AS "first_purchase",
        MAX(o."order_purchase_timestamp")                  AS "last_purchase"
    FROM "orders"        AS o
    JOIN "order_payments" AS op
      ON op."order_id" = o."order_id"
    GROUP BY o."customer_id"
),
calc AS (
    SELECT
        "customer_id",
        "number_of_orders",
        ROUND("total_paid" * 1.0 / "number_of_orders", 4) AS "avg_payment_per_order",
        CASE
            WHEN ((julianday("last_purchase") - julianday("first_purchase")) / 7.0) < 1
            THEN 1.0
            ELSE ROUND((julianday("last_purchase") - julianday("first_purchase")) / 7.0, 4)
        END                                              AS "customer_lifespan_weeks"
    FROM customer_stats
)
SELECT
    "customer_id",
    "number_of_orders",
    "avg_payment_per_order",
    "customer_lifespan_weeks"
FROM calc
ORDER BY "avg_payment_per_order" DESC, "customer_id"
LIMIT 3;