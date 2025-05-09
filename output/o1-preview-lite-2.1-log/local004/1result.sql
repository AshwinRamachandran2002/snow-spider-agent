SELECT
    o."customer_id",
    COUNT(DISTINCT o."order_id") AS "number_of_orders",
    ROUND(AVG(p."payment_value"), 4) AS "average_payment_per_order",
    CASE
        WHEN ((JULIANDAY(MAX(o."order_purchase_timestamp")) - JULIANDAY(MIN(o."order_purchase_timestamp"))) / 7.0) > 1.0 THEN
            ROUND(((JULIANDAY(MAX(o."order_purchase_timestamp")) - JULIANDAY(MIN(o."order_purchase_timestamp"))) / 7.0), 4)
        ELSE
            1.0
    END AS "customer_lifespan_weeks"
FROM "orders" AS o
JOIN "order_payments" AS p ON o."order_id" = p."order_id"
GROUP BY o."customer_id"
ORDER BY "average_payment_per_order" DESC
LIMIT 3;