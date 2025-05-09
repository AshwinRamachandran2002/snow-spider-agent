WITH delivered_orders AS (                       -- all delivered orders with customer data
    SELECT
        o."order_id",
        c."customer_unique_id",
        c."customer_city",
        c."customer_state"
    FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_ORDERS"  o
    JOIN BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_CUSTOMERS" c
          ON o."customer_id" = c."customer_id"
    WHERE o."order_status" = 'delivered'
),
payments_by_order AS (                           -- total payment for each order
    SELECT
        p."order_id",
        SUM(p."payment_value") AS "total_payment_value"
    FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_ORDER_PAYMENTS" p
    GROUP BY p."order_id"
),
customer_stats AS (                              -- delivered-order count & average payment per customer
    SELECT
        d."customer_unique_id",
        COUNT(DISTINCT d."order_id")                AS "delivered_order_count",
        AVG(p."total_payment_value")                AS "average_payment_value",
        MIN(d."customer_city")                      AS "customer_city",
        MIN(d."customer_state")                     AS "customer_state"
    FROM delivered_orders d
    LEFT JOIN payments_by_order p
           ON d."order_id" = p."order_id"
    GROUP BY d."customer_unique_id"
)
SELECT
    "customer_unique_id",
    "delivered_order_count",
    ROUND("average_payment_value", 4) AS "average_payment_value",
    "customer_city",
    "customer_state"
FROM customer_stats
ORDER BY "delivered_order_count" DESC NULLS LAST,
         "average_payment_value"   DESC NULLS LAST
LIMIT 3;