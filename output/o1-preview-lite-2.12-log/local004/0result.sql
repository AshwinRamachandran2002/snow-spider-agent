SELECT
    COUNT(DISTINCT o."order_id") AS "number_of_orders",
    SUM(op."payment_value") / COUNT(DISTINCT o."order_id") AS "average_payment_per_order",
    CASE
        WHEN (julianday(MAX(o."order_purchase_timestamp")) - julianday(MIN(o."order_purchase_timestamp"))) < 7
            THEN 1.0
        ELSE
            (julianday(MAX(o."order_purchase_timestamp")) - julianday(MIN(o."order_purchase_timestamp"))) / 7.0
    END AS "lifespan_weeks"
FROM
    "orders" AS o
JOIN
    "order_payments" AS op ON o."order_id" = op."order_id"
GROUP BY
    o."customer_id"
ORDER BY
    "average_payment_per_order" DESC
LIMIT 3;