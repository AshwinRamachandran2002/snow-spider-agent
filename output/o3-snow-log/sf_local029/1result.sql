WITH delivered_orders AS (
    /* all orders that reached the “delivered” status with the customer info attached */
    SELECT  o."order_id",
            c."customer_unique_id",
            c."customer_city",
            c."customer_state"
    FROM    BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_ORDERS"   o
    JOIN    BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_CUSTOMERS" c
           ON o."customer_id" = c."customer_id"
    WHERE   o."order_status" = 'delivered'
),
payments_per_order AS (
    /* total amount paid for every order (may have several payment rows) */
    SELECT  op."order_id",
            SUM(op."payment_value") AS total_payment_value
    FROM    BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_ORDER_PAYMENTS" op
    GROUP BY op."order_id"
)
SELECT  d."customer_unique_id",
        COUNT(*)                                      AS delivered_orders,
        ROUND(AVG(p.total_payment_value), 4)          AS avg_payment_value,
        MIN(d."customer_city")                        AS customer_city,
        MIN(d."customer_state")                       AS customer_state
FROM    delivered_orders d
LEFT JOIN payments_per_order p
       ON d."order_id" = p."order_id"
GROUP BY d."customer_unique_id"
ORDER BY delivered_orders DESC NULLS LAST
LIMIT 3;