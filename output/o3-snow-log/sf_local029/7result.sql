WITH delivered_orders AS (
    SELECT 
        o."order_id",
        c."customer_unique_id",
        c."customer_city",
        c."customer_state"
    FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_ORDERS"      o
    JOIN BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_CUSTOMERS"   c
          ON o."customer_id" = c."customer_id"
    WHERE o."order_status" = 'delivered'
),
payments_per_order AS (
    SELECT 
        op."order_id",
        SUM(op."payment_value") AS "order_payment_value"
    FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_ORDER_PAYMENTS" op
    GROUP BY op."order_id"
),
delivered_with_payments AS (
    SELECT 
        d."customer_unique_id",
        d."customer_city",
        d."customer_state",
        d."order_id",
        COALESCE(p."order_payment_value", 0) AS "order_payment_value"
    FROM delivered_orders d
    LEFT JOIN payments_per_order p
           ON d."order_id" = p."order_id"
),
customer_agg AS (
    SELECT
        "customer_unique_id",
        COUNT("order_id")                          AS "delivered_orders_cnt",
        AVG("order_payment_value")                 AS "avg_payment_value",
        ANY_VALUE("customer_city")                 AS "customer_city",
        ANY_VALUE("customer_state")                AS "customer_state"
    FROM delivered_with_payments
    GROUP BY "customer_unique_id"
)
SELECT
    "customer_unique_id",
    ROUND("avg_payment_value", 4)  AS "average_payment_value",
    "customer_city",
    "customer_state"
FROM customer_agg
ORDER BY "delivered_orders_cnt" DESC NULLS LAST
LIMIT 3;