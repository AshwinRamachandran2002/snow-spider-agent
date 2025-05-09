SELECT
  c."customer_unique_id",
  MIN(c."customer_city")   AS "customer_city",
  MIN(c."customer_state")  AS "customer_state",
  COUNT(DISTINCT o."order_id") AS "delivered_orders",
  ROUND(AVG(p."payment_value"), 4) AS "avg_payment_value"
FROM "olist_orders" AS o
JOIN "olist_order_payments" AS p
     ON o."order_id" = p."order_id"
JOIN "olist_customers" AS c
     ON o."customer_id" = c."customer_id"
WHERE o."order_status" = 'delivered'
GROUP BY c."customer_unique_id"
ORDER BY "delivered_orders" DESC
LIMIT 3;