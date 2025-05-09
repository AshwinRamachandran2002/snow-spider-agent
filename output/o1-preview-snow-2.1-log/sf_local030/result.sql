SELECT
    "c"."customer_city" AS "city",
    ROUND(AVG("p"."payment_value"), 4) AS "average_payment",
    COUNT(DISTINCT "o"."order_id") AS "order_count"
FROM
    "BRAZILIAN_E_COMMERCE"."BRAZILIAN_E_COMMERCE"."OLIST_CUSTOMERS" AS "c"
    JOIN "BRAZILIAN_E_COMMERCE"."BRAZILIAN_E_COMMERCE"."OLIST_ORDERS" AS "o"
        ON "c"."customer_id" = "o"."customer_id"
    JOIN "BRAZILIAN_E_COMMERCE"."BRAZILIAN_E_COMMERCE"."OLIST_ORDER_PAYMENTS" AS "p"
        ON "o"."order_id" = "p"."order_id"
WHERE
    "o"."order_status" = 'delivered'
GROUP BY
    "c"."customer_city"
ORDER BY
    SUM("p"."payment_value") ASC
LIMIT 5;