WITH order_pay_totals AS (
    SELECT "order_id",
           SUM("payment_value") AS "order_payment_total"
    FROM "order_payments"
    GROUP BY "order_id"
),
customer_orders AS (
    SELECT  o."customer_id",
            o."order_id",
            o."order_purchase_timestamp",
            t."order_payment_total"
    FROM "orders" AS o
    JOIN order_pay_totals AS t
      ON o."order_id" = t."order_id"
),
customer_metrics AS (
    SELECT  "customer_id",
            COUNT(DISTINCT "order_id")            AS "order_count",
            AVG("order_payment_total")            AS "average_payment_per_order",
            MIN("order_purchase_timestamp")       AS "first_purchase",
            MAX("order_purchase_timestamp")       AS "last_purchase"
    FROM customer_orders
    GROUP BY "customer_id"
),
final_metrics AS (
    SELECT  "customer_id",
            "order_count",
            "average_payment_per_order",
            CASE
                WHEN (julianday("last_purchase") - julianday("first_purchase")) / 7.0 < 1
                THEN 1.0
                ELSE (julianday("last_purchase") - julianday("first_purchase")) / 7.0
            END                                   AS "customer_lifespan_weeks"
    FROM customer_metrics
)
SELECT  "customer_id",
        "order_count",
        ROUND("average_payment_per_order",4)  AS "average_payment_per_order",
        ROUND("customer_lifespan_weeks",4)    AS "customer_lifespan_weeks"
FROM final_metrics
ORDER BY "average_payment_per_order" DESC
LIMIT 3;