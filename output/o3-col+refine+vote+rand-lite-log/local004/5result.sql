WITH payments_per_order AS (
    SELECT "order_id",
           SUM("payment_value") AS "total_payment"
    FROM   "order_payments"
    GROUP  BY "order_id"
),
customer_orders AS (
    SELECT c."customer_unique_id",
           o."order_id",
           o."order_purchase_timestamp",
           p."total_payment"
    FROM   "orders"            AS o
    JOIN   payments_per_order  AS p ON p."order_id" = o."order_id"
    JOIN   "customers"         AS c ON c."customer_id" = o."customer_id"
)
SELECT
       co."customer_unique_id",
       COUNT(DISTINCT co."order_id")                                       AS "num_orders",
       ROUND(AVG(co."total_payment"), 4)                                   AS "avg_payment_per_order",
       ROUND(
             CASE
                  WHEN (julianday(MAX(co."order_purchase_timestamp"))
                        - julianday(MIN(co."order_purchase_timestamp"))) < 7
                  THEN 1.0
                  ELSE (julianday(MAX(co."order_purchase_timestamp"))
                        - julianday(MIN(co."order_purchase_timestamp"))) / 7.0
             END, 4)                                                       AS "customer_lifespan_weeks"
FROM   customer_orders AS co
GROUP  BY co."customer_unique_id"
ORDER  BY "avg_payment_per_order" DESC
LIMIT 3;