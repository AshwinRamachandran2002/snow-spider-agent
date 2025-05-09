WITH delivered_orders AS (   -- only delivered orders
    SELECT "order_id",
           "customer_id"
    FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_ORDERS"
    WHERE "order_status" = 'delivered'
),
order_payment_totals AS (    -- total paid per order
    SELECT "order_id",
           SUM("payment_value") AS "order_total_value"
    FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_ORDER_PAYMENTS"
    GROUP BY "order_id"
),
delivered_orders_with_payment AS (  -- attach payment totals to delivered orders
    SELECT d."customer_id",
           d."order_id",
           COALESCE(p."order_total_value",0) AS "order_total_value"
    FROM delivered_orders d
    LEFT JOIN order_payment_totals p
           ON d."order_id" = p."order_id"
),
customer_level AS (   -- aggregate by customer_unique_id
    SELECT c."customer_unique_id",
           c."customer_city",
           c."customer_state",
           COUNT(*)                          AS "delivered_orders_count",
           AVG(d."order_total_value")        AS "avg_payment_value"
    FROM delivered_orders_with_payment d
    JOIN BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_CUSTOMERS" c
         ON d."customer_id" = c."customer_id"
    GROUP BY c."customer_unique_id",
             c."customer_city",
             c."customer_state"
)
SELECT "customer_unique_id",
       "delivered_orders_count",
       ROUND("avg_payment_value",4) AS "avg_payment_value",
       "customer_city",
       "customer_state"
FROM customer_level
ORDER BY "delivered_orders_count" DESC NULLS LAST
LIMIT 3;