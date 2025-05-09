SELECT city_stats."customer_city",
       city_stats."average_payment",
       city_stats."order_count"
FROM (
  SELECT c."customer_city",
         SUM(p."payment_value") AS "city_total_payment",
         AVG(p."payment_value") AS "average_payment",
         COUNT(DISTINCT o."order_id") AS "order_count"
  FROM "olist_order_payments" AS p
  INNER JOIN "olist_orders" AS o ON p."order_id" = o."order_id"
  INNER JOIN "olist_customers" AS c ON o."customer_id" = c."customer_id"
  WHERE o."order_status" = 'delivered'
  GROUP BY c."customer_city"
) AS city_stats
ORDER BY city_stats."city_total_payment" ASC
LIMIT 5;