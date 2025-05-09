SELECT
    c."customer_unique_id",
    COUNT(*)                                      AS delivered_orders,
    ROUND(AVG(p."payment_value"), 4)              AS avg_payment,
    MIN(c."customer_city")                        AS city,
    MIN(c."customer_state")                       AS state
FROM   "olist_orders"          AS o
JOIN   "olist_customers"       AS c ON o."customer_id" = c."customer_id"
JOIN   "olist_order_payments"  AS p ON o."order_id"    = p."order_id"
WHERE  o."order_status" = 'delivered'
GROUP  BY c."customer_unique_id"
ORDER  BY delivered_orders DESC
LIMIT  3;