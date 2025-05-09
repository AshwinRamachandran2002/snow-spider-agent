-- 3 customers with the highest average payment per order,
-- together with their number of orders, average payment and lifespan in weeks
SELECT
    o."customer_id",
    COUNT(DISTINCT o."order_id")                                           AS "num_orders",
    AVG(op."payment_value")                                                AS "avg_payment_per_order",
    CASE
        WHEN (JULIANDAY(MAX(o."order_purchase_timestamp")) -
              JULIANDAY(MIN(o."order_purchase_timestamp"))) < 7
        THEN 1.0
        ELSE (JULIANDAY(MAX(o."order_purchase_timestamp")) -
              JULIANDAY(MIN(o."order_purchase_timestamp"))) / 7.0
    END                                                                    AS "lifespan_weeks"
FROM "orders"            AS o
JOIN "order_payments"    AS op  ON o."order_id" = op."order_id"
GROUP BY o."customer_id"
ORDER BY "avg_payment_per_order" DESC
LIMIT 3;