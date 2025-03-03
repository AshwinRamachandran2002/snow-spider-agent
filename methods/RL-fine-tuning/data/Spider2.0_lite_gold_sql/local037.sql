WITH single_payment_type_orders AS (
    SELECT "order_id"
    FROM "olist_order_payments"
    GROUP BY "order_id"
    HAVING COUNT(DISTINCT "payment_type") = 1
)
SELECT "products"."product_category_name" AS "Product_Category",
       COUNT(*) AS "Number_of_Payments"
FROM "olist_order_items" AS "order_items"
JOIN single_payment_type_orders AS "single_orders"
  ON "order_items"."order_id" = "single_orders"."order_id"
JOIN "olist_products" AS "products"
  ON "order_items"."product_id" = "products"."product_id"
GROUP BY "products"."product_category_name"
ORDER BY "Number_of_Payments" DESC
LIMIT 3;