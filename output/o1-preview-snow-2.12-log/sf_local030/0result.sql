WITH city_payments AS (
  SELECT c."customer_city",
         SUM(p."payment_value") AS "total_payments",
         COUNT(DISTINCT o."order_id") AS "total_delivered_orders"
  FROM "BRAZILIAN_E_COMMERCE"."BRAZILIAN_E_COMMERCE"."OLIST_CUSTOMERS" c
  JOIN "BRAZILIAN_E_COMMERCE"."BRAZILIAN_E_COMMERCE"."OLIST_ORDERS" o
    ON c."customer_id" = o."customer_id"
  JOIN "BRAZILIAN_E_COMMERCE"."BRAZILIAN_E_COMMERCE"."OLIST_ORDER_PAYMENTS" p
    ON o."order_id" = p."order_id"
  WHERE o."order_status" = 'delivered'
  GROUP BY c."customer_city"
)
SELECT AVG("total_payments") AS "average_total_payments",
       AVG("total_delivered_orders") AS "average_total_order_counts"
FROM (
  SELECT *
  FROM city_payments
  ORDER BY "total_payments" ASC
  LIMIT 5
) AS t;