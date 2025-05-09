SELECT
    COUNT(DISTINCT o."order_id") AS number_of_orders,
    ROUND(AVG(op_total.order_total_payment), 4) AS average_payment_per_order,
    CASE
        WHEN ((JULIANDAY(MAX(o."order_purchase_timestamp")) - JULIANDAY(MIN(o."order_purchase_timestamp"))) / 7.0) < 1.0 THEN 1.0
        ELSE ROUND(((JULIANDAY(MAX(o."order_purchase_timestamp")) - JULIANDAY(MIN(o."order_purchase_timestamp"))) / 7.0), 4)
    END AS lifespan_weeks
FROM "orders" AS o
JOIN (
    SELECT "order_id", SUM("payment_value") AS order_total_payment
    FROM "order_payments"
    GROUP BY "order_id"
) AS op_total ON o."order_id" = op_total."order_id"
GROUP BY o."customer_id"
ORDER BY average_payment_per_order DESC
LIMIT 3;