SELECT
    COUNT(DISTINCT o."order_id") AS "number_of_orders",
    printf('%.4f', AVG(p."payment_value")) AS "average_payment_per_order",
    CASE
        WHEN (JULIANDAY(MAX(o."order_purchase_timestamp")) - JULIANDAY(MIN(o."order_purchase_timestamp"))) < 7
        THEN 1.0
        ELSE printf('%.4f', (JULIANDAY(MAX(o."order_purchase_timestamp")) - JULIANDAY(MIN(o."order_purchase_timestamp"))) / 7.0)
    END AS "lifespan_weeks"
FROM "orders" AS o
JOIN "order_payments" AS p ON o."order_id" = p."order_id"
GROUP BY o."customer_id"
ORDER BY AVG(p."payment_value") DESC
LIMIT 3;