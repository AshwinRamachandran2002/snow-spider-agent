SELECT 
    o."customer_id",
    COUNT(DISTINCT o."order_id") AS "number_of_orders",
    ROUND(AVG(p."payment_value"), 4) AS "average_payment_per_order",
    CASE
        WHEN (DATEDIFF('day', 
                       MIN(TRY_TO_TIMESTAMP(o."order_purchase_timestamp", 'YYYY-MM-DD HH24:MI:SS')), 
                       MAX(TRY_TO_TIMESTAMP(o."order_purchase_timestamp", 'YYYY-MM-DD HH24:MI:SS'))) + 1) < 7 THEN 1.0000
        ELSE ROUND(
            ((DATEDIFF('day', 
                       MIN(TRY_TO_TIMESTAMP(o."order_purchase_timestamp", 'YYYY-MM-DD HH24:MI:SS')), 
                       MAX(TRY_TO_TIMESTAMP(o."order_purchase_timestamp", 'YYYY-MM-DD HH24:MI:SS'))) + 1) / 7.0),
            4)
    END AS "lifespan_in_weeks"
FROM 
    E_COMMERCE.E_COMMERCE.ORDERS o
JOIN 
    E_COMMERCE.E_COMMERCE.ORDER_PAYMENTS p 
    ON o."order_id" = p."order_id"
WHERE 
    TRY_TO_TIMESTAMP(o."order_purchase_timestamp", 'YYYY-MM-DD HH24:MI:SS') IS NOT NULL
GROUP BY 
    o."customer_id"
ORDER BY 
    "average_payment_per_order" DESC NULLS LAST
LIMIT 3;