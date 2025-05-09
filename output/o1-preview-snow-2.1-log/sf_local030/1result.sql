SELECT city_stats."customer_city" AS "city", 
       ROUND(city_stats."average_payment", 4) AS "average_payment", 
       city_stats."order_count"
FROM (
  SELECT c."customer_city", 
         AVG(p."payment_value") AS "average_payment", 
         COUNT(DISTINCT o."order_id") AS "order_count", 
         SUM(p."payment_value") AS "total_payments"
  FROM "BRAZILIAN_E_COMMERCE"."BRAZILIAN_E_COMMERCE"."OLIST_ORDERS" o
  JOIN "BRAZILIAN_E_COMMERCE"."BRAZILIAN_E_COMMERCE"."OLIST_CUSTOMERS" c
    ON o."customer_id" = c."customer_id"
  JOIN "BRAZILIAN_E_COMMERCE"."BRAZILIAN_E_COMMERCE"."OLIST_ORDER_PAYMENTS" p
    ON o."order_id" = p."order_id"
  WHERE o."order_status" = 'delivered'
  GROUP BY c."customer_city"
  HAVING COUNT(DISTINCT o."order_id") >= 5
) city_stats
ORDER BY city_stats."total_payments" ASC
LIMIT 5;