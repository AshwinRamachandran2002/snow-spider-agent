SELECT
    o."customer_id",
    COUNT(DISTINCT o."order_id") AS "number_of_orders",
    ROUND(AVG(t."total_payment_per_order"), 4) AS "average_payment_per_order",
    ROUND(
        CASE
            WHEN DATEDIFF('week', MIN(TO_TIMESTAMP(o."order_purchase_timestamp")), MAX(TO_TIMESTAMP(o."order_purchase_timestamp"))) < 1 THEN 1.0
            ELSE DATEDIFF('week', MIN(TO_TIMESTAMP(o."order_purchase_timestamp")), MAX(TO_TIMESTAMP(o."order_purchase_timestamp")))
        END,
        4
    ) AS "lifespan_in_weeks"
FROM E_COMMERCE.E_COMMERCE.ORDERS o
JOIN (
    SELECT p."order_id", SUM(p."payment_value") AS "total_payment_per_order"
    FROM E_COMMERCE.E_COMMERCE.ORDER_PAYMENTS p
    GROUP BY p."order_id"
) t ON o."order_id" = t."order_id"
GROUP BY o."customer_id"
ORDER BY "average_payment_per_order" DESC NULLS LAST
LIMIT 3;