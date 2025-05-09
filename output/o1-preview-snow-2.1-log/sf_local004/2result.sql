SELECT
    c."customer_id",
    COUNT(DISTINCT o."order_id") AS "number_of_orders",
    ROUND(SUM(p."payment_value") / COUNT(DISTINCT o."order_id"), 4) AS "average_payment_per_order",
    CASE
        WHEN DATEDIFF(week, MIN(o."order_purchase_timestamp"), MAX(o."order_purchase_timestamp")) >= 1 THEN 
            CAST(DATEDIFF(week, MIN(o."order_purchase_timestamp"), MAX(o."order_purchase_timestamp")) AS FLOAT)
        ELSE
            1.0
    END AS "lifespan_in_weeks"
FROM E_COMMERCE.E_COMMERCE.CUSTOMERS c
JOIN E_COMMERCE.E_COMMERCE.ORDERS o ON c."customer_id" = o."customer_id"
JOIN E_COMMERCE.E_COMMERCE.ORDER_PAYMENTS p ON o."order_id" = p."order_id"
GROUP BY c."customer_id"
ORDER BY "average_payment_per_order" DESC NULLS LAST
LIMIT 3;