WITH customer_orders AS (
  SELECT
    c."customer_unique_id",
    c."customer_city" AS "city",
    c."customer_state" AS "state",
    COUNT(*) AS "num_delivered_orders",
    AVG(p."payment_value") AS "average_payment_value"
  FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE.OLIST_ORDERS o
  INNER JOIN BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE.OLIST_CUSTOMERS c
    ON o."customer_id" = c."customer_id"
  INNER JOIN BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE.OLIST_ORDER_PAYMENTS p
    ON o."order_id" = p."order_id"
  WHERE o."order_status" = 'delivered'
  GROUP BY c."customer_unique_id", c."customer_city", c."customer_state"
)
SELECT
  "customer_unique_id",
  ROUND("average_payment_value", 4) AS "average_payment_value",
  "city",
  "state"
FROM customer_orders
ORDER BY "num_delivered_orders" DESC NULLS LAST, "customer_unique_id"
LIMIT 3;