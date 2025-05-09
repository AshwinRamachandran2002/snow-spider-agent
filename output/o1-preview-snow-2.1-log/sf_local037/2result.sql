SELECT PR."product_category_name", COUNT(*) AS "number_of_payments"
FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_ORDER_PAYMENTS" P
JOIN BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_ORDER_ITEMS" I
    ON P."order_id" = I."order_id"
JOIN BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_PRODUCTS" PR
    ON I."product_id" = PR."product_id"
WHERE P."payment_installments" = 1
GROUP BY PR."product_category_name"
ORDER BY "number_of_payments" DESC NULLS LAST
LIMIT 3;