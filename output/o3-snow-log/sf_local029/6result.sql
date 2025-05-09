WITH delivered_orders AS (
    SELECT
        o."order_id",
        c."customer_unique_id",
        c."customer_city",
        c."customer_state"
    FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_ORDERS" o
    JOIN BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_CUSTOMERS" c
        ON o."customer_id" = c."customer_id"
    WHERE o."order_status" = 'delivered'
),
order_payments AS (
    SELECT
        "order_id",
        SUM("payment_value") AS "order_payment_total"
    FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_ORDER_PAYMENTS"
    GROUP BY "order_id"
)
SELECT
    d."customer_unique_id",
    COUNT(*)                                             AS "delivered_orders",
    ROUND(AVG(p."order_payment_total"), 4)               AS "average_payment_value",
    MIN(d."customer_city")                               AS "customer_city",
    MIN(d."customer_state")                              AS "customer_state"
FROM delivered_orders d
LEFT JOIN order_payments p
    ON d."order_id" = p."order_id"
GROUP BY d."customer_unique_id"
ORDER BY "delivered_orders" DESC NULLS LAST
LIMIT 3;