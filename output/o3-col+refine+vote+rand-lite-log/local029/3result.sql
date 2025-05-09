WITH "order_payments" AS (
  SELECT "order_id",
         SUM("payment_value") AS "order_total_payment"
  FROM "olist_order_payments"
  GROUP BY "order_id"
)
SELECT
  c."customer_unique_id",
  COUNT(*)                       AS "delivered_orders",
  AVG(op."order_total_payment")  AS "avg_payment",
  MIN(c."customer_city")         AS "customer_city",
  MIN(c."customer_state")        AS "customer_state"
FROM "olist_orders"   AS o
JOIN "olist_customers" AS c  ON o."customer_id" = c."customer_id"
JOIN "order_payments"  AS op ON o."order_id"    = op."order_id"
WHERE o."order_status" = 'delivered'
GROUP BY c."customer_unique_id"
ORDER BY "delivered_orders" DESC
LIMIT 3;