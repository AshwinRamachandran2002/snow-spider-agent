WITH order_payments_agg AS (
    SELECT "order_id",
           SUM("payment_value") AS "order_total_payment"
    FROM "order_payments"
    GROUP BY "order_id"
),
customer_metrics AS (
    SELECT  o."customer_id",
            COUNT(DISTINCT o."order_id")                               AS "num_orders",
            AVG(op."order_total_payment")                              AS "avg_payment_per_order",
            CASE
                 WHEN (JULIANDAY(MAX(o."order_purchase_timestamp"))
                       - JULIANDAY(MIN(o."order_purchase_timestamp"))) < 7
                 THEN 1.0
                 ELSE (JULIANDAY(MAX(o."order_purchase_timestamp"))
                       - JULIANDAY(MIN(o."order_purchase_timestamp"))) / 7.0
            END                                                        AS "lifespan_weeks"
    FROM "orders" AS o
    JOIN order_payments_agg AS op
      ON o."order_id" = op."order_id"
    GROUP BY o."customer_id"
),
ranked AS (
    SELECT cm.*,
           ROW_NUMBER() OVER (ORDER BY cm."avg_payment_per_order" DESC) AS rn
    FROM customer_metrics AS cm
)
SELECT "customer_id",
       "num_orders",
       ROUND("avg_payment_per_order", 4)    AS "avg_payment_per_order",
       ROUND("lifespan_weeks", 4)           AS "customer_lifespan_weeks"
FROM ranked
WHERE rn <= 3;