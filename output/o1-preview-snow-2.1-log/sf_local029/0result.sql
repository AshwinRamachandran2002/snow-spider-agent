SELECT sub."Customer_Unique_ID",
       sub."Average_Payment_Value",
       sub."City",
       sub."State"
FROM (
    SELECT c."customer_unique_id" AS "Customer_Unique_ID",
           ROUND(AVG(p."payment_value"), 4) AS "Average_Payment_Value",
           c."customer_city" AS "City",
           c."customer_state" AS "State",
           COUNT(o."order_id") AS "Delivered_Orders_Count"
    FROM "BRAZILIAN_E_COMMERCE"."BRAZILIAN_E_COMMERCE"."OLIST_CUSTOMERS" c
    JOIN "BRAZILIAN_E_COMMERCE"."BRAZILIAN_E_COMMERCE"."OLIST_ORDERS" o
      ON c."customer_id" = o."customer_id"
    JOIN "BRAZILIAN_E_COMMERCE"."BRAZILIAN_E_COMMERCE"."OLIST_ORDER_PAYMENTS" p
      ON o."order_id" = p."order_id"
    WHERE o."order_status" = 'delivered'
    GROUP BY c."customer_unique_id", c."customer_city", c."customer_state"
) sub
ORDER BY sub."Delivered_Orders_Count" DESC NULLS LAST
LIMIT 3;