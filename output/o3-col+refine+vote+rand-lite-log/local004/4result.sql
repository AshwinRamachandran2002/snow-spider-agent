WITH payments_per_order AS (
    SELECT "order_id",
           SUM("payment_value") AS "total_payment_per_order"
    FROM   "order_payments"
    GROUP  BY "order_id"
),
customer_payments AS (
    SELECT o."customer_id",
           COUNT(DISTINCT o."order_id")           AS "n_orders",
           AVG(p."total_payment_per_order")       AS "avg_payment_per_order"
    FROM   "orders" o
    JOIN   payments_per_order p
           ON p."order_id" = o."order_id"
    GROUP  BY o."customer_id"
),
customer_dates AS (
    SELECT "customer_id",
           DATE(MIN("order_purchase_timestamp")) AS "first_purchase",
           DATE(MAX("order_purchase_timestamp")) AS "last_purchase"
    FROM   "orders"
    GROUP  BY "customer_id"
),
customer_summary AS (
    SELECT cp."customer_id",
           cp."n_orders",
           cp."avg_payment_per_order",
           CASE
             WHEN (julianday(cd."last_purchase") - julianday(cd."first_purchase")) < 7
                  THEN 1.0
             ELSE (julianday(cd."last_purchase") - julianday(cd."first_purchase")) / 7.0
           END AS "customer_lifespan_weeks"
    FROM   customer_payments cp
    JOIN   customer_dates cd
           ON cd."customer_id" = cp."customer_id"
)
SELECT "customer_id",
       "n_orders",
       ROUND("avg_payment_per_order", 4)  AS "avg_payment_per_order",
       ROUND("customer_lifespan_weeks",4) AS "customer_lifespan_weeks"
FROM   customer_summary
ORDER BY "avg_payment_per_order" DESC
LIMIT 3;