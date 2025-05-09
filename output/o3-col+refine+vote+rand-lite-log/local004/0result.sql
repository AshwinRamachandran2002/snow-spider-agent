WITH pay_per_order AS (
    SELECT  o."order_id",
            o."customer_id",
            SUM(p."payment_value") AS order_payment
    FROM    "orders"         AS o
    JOIN    "order_payments" AS p USING ("order_id")
    GROUP BY o."order_id"
),
customer_stats AS (
    SELECT  "customer_id",
            COUNT(*)              AS number_of_orders,
            AVG(order_payment)    AS average_payment_per_order
    FROM    pay_per_order
    GROUP BY "customer_id"
),
customer_lifespan AS (
    SELECT  "customer_id",
            CASE
                WHEN (julianday(MAX("order_purchase_timestamp")) -
                      julianday(MIN("order_purchase_timestamp"))) < 7
                     THEN 1.0
                ELSE (julianday(MAX("order_purchase_timestamp")) -
                      julianday(MIN("order_purchase_timestamp"))) / 7
            END AS customer_lifespan_weeks
    FROM    "orders"
    GROUP BY "customer_id"
)
SELECT  cs."customer_id",
        cs.number_of_orders,
        ROUND(cs.average_payment_per_order, 4) AS average_payment_per_order,
        ROUND(cl.customer_lifespan_weeks, 4)   AS customer_lifespan_weeks
FROM    customer_stats   AS cs
JOIN    customer_lifespan AS cl USING ("customer_id")
ORDER BY cs.average_payment_per_order DESC
LIMIT 3;