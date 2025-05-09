WITH order_totals AS (
    SELECT
        op."order_id",
        SUM(op."payment_value") AS "order_total_payment"
    FROM "order_payments" op
    GROUP BY op."order_id"
),
customer_orders AS (
    SELECT
        o."customer_id",
        ot."order_total_payment",
        o."order_purchase_timestamp"
    FROM "orders" o
    JOIN order_totals ot
      ON ot."order_id" = o."order_id"
),
metrics AS (
    SELECT
        co."customer_id",
        COUNT(*) AS "num_orders",
        AVG(co."order_total_payment") AS "avg_payment_per_order",
        CASE
            WHEN (julianday(MAX(co."order_purchase_timestamp")) -
                  julianday(MIN(co."order_purchase_timestamp"))) < 7
            THEN 1.0
            ELSE (julianday(MAX(co."order_purchase_timestamp")) -
                  julianday(MIN(co."order_purchase_timestamp"))) / 7.0
        END AS "customer_lifespan_weeks"
    FROM customer_orders co
    GROUP BY co."customer_id"
)
SELECT
    m."customer_id",
    m."num_orders",
    ROUND(m."avg_payment_per_order", 4)  AS "avg_payment_per_order",
    ROUND(m."customer_lifespan_weeks", 4) AS "customer_lifespan_weeks"
FROM metrics m
ORDER BY m."avg_payment_per_order" DESC
LIMIT 3;