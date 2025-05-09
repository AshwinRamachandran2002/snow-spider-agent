WITH single_payment_type_orders AS (
    SELECT "order_id"
    FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_ORDER_PAYMENTS"
    GROUP BY "order_id"
    HAVING COUNT(DISTINCT "payment_type") = 1
)

SELECT t3."product_category_name", COUNT(*) AS "number_of_payments"
FROM single_payment_type_orders t0
INNER JOIN BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_ORDER_ITEMS" t2
    ON t0."order_id" = t2."order_id"
INNER JOIN BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_PRODUCTS" t3
    ON t2."product_id" = t3."product_id"
GROUP BY t3."product_category_name"
ORDER BY COUNT(*) DESC NULLS LAST
LIMIT 3;