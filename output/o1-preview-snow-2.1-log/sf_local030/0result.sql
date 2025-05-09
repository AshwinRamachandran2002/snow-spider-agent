SELECT city_payments."customer_city" AS "city", ROUND(city_stats."average_payment", 4) AS "average_payment", city_stats."order_count"
FROM
(
    SELECT c."customer_city", SUM(op."payment_value") AS "total_payments"
    FROM "BRAZILIAN_E_COMMERCE"."BRAZILIAN_E_COMMERCE"."OLIST_ORDERS" AS o
    JOIN "BRAZILIAN_E_COMMERCE"."BRAZILIAN_E_COMMERCE"."OLIST_CUSTOMERS" AS c
      ON o."customer_id" = c."customer_id"
    JOIN "BRAZILIAN_E_COMMERCE"."BRAZILIAN_E_COMMERCE"."OLIST_ORDER_PAYMENTS" AS op
      ON o."order_id" = op."order_id"
    WHERE o."order_status" = 'delivered'
    GROUP BY c."customer_city"
    ORDER BY "total_payments" ASC NULLS LAST
    LIMIT 5
) AS city_payments
JOIN
(
    SELECT c."customer_city", ROUND(AVG(op."payment_value"), 4) AS "average_payment", COUNT(DISTINCT o."order_id") AS "order_count"
    FROM "BRAZILIAN_E_COMMERCE"."BRAZILIAN_E_COMMERCE"."OLIST_ORDERS" AS o
    JOIN "BRAZILIAN_E_COMMERCE"."BRAZILIAN_E_COMMERCE"."OLIST_CUSTOMERS" AS c
      ON o."customer_id" = c."customer_id"
    JOIN "BRAZILIAN_E_COMMERCE"."BRAZILIAN_E_COMMERCE"."OLIST_ORDER_PAYMENTS" AS op
      ON o."order_id" = op."order_id"
    WHERE o."order_status" = 'delivered'
    GROUP BY c."customer_city"
) AS city_stats
ON city_payments."customer_city" = city_stats."customer_city"
ORDER BY city_payments."total_payments" ASC;