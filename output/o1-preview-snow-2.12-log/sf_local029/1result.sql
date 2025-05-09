SELECT
    c."customer_unique_id",
    AVG(p."payment_value") AS "average_payment_value",
    c."customer_city" AS "city",
    c."customer_state" AS "state"
FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE.OLIST_ORDERS o
JOIN BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE.OLIST_CUSTOMERS c
    ON o."customer_id" = c."customer_id"
JOIN BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE.OLIST_ORDER_PAYMENTS p
    ON o."order_id" = p."order_id"
WHERE o."order_status" = 'delivered'
GROUP BY
    c."customer_unique_id",
    c."customer_city",
    c."customer_state"
ORDER BY COUNT(*) DESC NULLS LAST
LIMIT 3;