SELECT
  c."customer_unique_id" AS "Customer_Unique_ID",
  ROUND(AVG(p."payment_value"), 4) AS "Average_Payment_Value",
  c."customer_city" AS "City",
  c."customer_state" AS "State"
FROM "BRAZILIAN_E_COMMERCE"."BRAZILIAN_E_COMMERCE"."OLIST_CUSTOMERS" c
JOIN "BRAZILIAN_E_COMMERCE"."BRAZILIAN_E_COMMERCE"."OLIST_ORDERS" o
  ON c."customer_id" = o."customer_id"
JOIN "BRAZILIAN_E_COMMERCE"."BRAZILIAN_E_COMMERCE"."OLIST_ORDER_PAYMENTS" p
  ON o."order_id" = p."order_id"
WHERE o."order_status" = 'delivered'
  AND c."customer_unique_id" IN (
    SELECT c2."customer_unique_id"
    FROM "BRAZILIAN_E_COMMERCE"."BRAZILIAN_E_COMMERCE"."OLIST_CUSTOMERS" c2
    JOIN "BRAZILIAN_E_COMMERCE"."BRAZILIAN_E_COMMERCE"."OLIST_ORDERS" o2
      ON c2."customer_id" = o2."customer_id"
    WHERE o2."order_status" = 'delivered'
    GROUP BY c2."customer_unique_id"
    ORDER BY COUNT(o2."order_id") DESC NULLS LAST
    LIMIT 3
  )
GROUP BY c."customer_unique_id", c."customer_city", c."customer_state"
ORDER BY COUNT(DISTINCT o."order_id") DESC NULLS LAST
LIMIT 3;