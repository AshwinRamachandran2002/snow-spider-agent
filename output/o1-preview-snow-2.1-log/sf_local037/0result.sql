SELECT trans."product_category_name_english" AS "product_category_name",
       COUNT(*) AS "number_of_payments"
FROM "BRAZILIAN_E_COMMERCE"."BRAZILIAN_E_COMMERCE"."OLIST_ORDER_PAYMENTS" p
JOIN "BRAZILIAN_E_COMMERCE"."BRAZILIAN_E_COMMERCE"."OLIST_ORDER_ITEMS" oi
  ON p."order_id" = oi."order_id"
JOIN "BRAZILIAN_E_COMMERCE"."BRAZILIAN_E_COMMERCE"."OLIST_PRODUCTS" prod
  ON oi."product_id" = prod."product_id"
JOIN "BRAZILIAN_E_COMMERCE"."BRAZILIAN_E_COMMERCE"."PRODUCT_CATEGORY_NAME_TRANSLATION" trans
  ON prod."product_category_name" = trans."product_category_name"
WHERE p."payment_installments" = 1
GROUP BY trans."product_category_name_english"
ORDER BY "number_of_payments" DESC NULLS LAST
LIMIT 3;