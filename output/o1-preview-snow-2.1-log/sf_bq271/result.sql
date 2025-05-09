SELECT
  TO_CHAR(TO_TIMESTAMP_NTZ("ORDERS"."created_at" / 1000000), 'YYYY-MM') AS "Month",
  "USERS"."country" AS "Country",
  "PRODUCTS"."department" AS "Product_Department",
  "PRODUCTS"."category" AS "Product_Category",
  COUNT(DISTINCT "ORDERS"."order_id") AS "Number_of_Orders",
  COUNT(DISTINCT "ORDERS"."user_id") AS "Number_of_Unique_Purchasers",
  ROUND(SUM("PRODUCTS"."retail_price" - "PRODUCTS"."cost"), 4) AS "Profit"
FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"
JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"
  ON "ORDERS"."order_id" = "ORDER_ITEMS"."order_id"
JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"
  ON "ORDER_ITEMS"."product_id" = "PRODUCTS"."id"
JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS"
  ON "ORDERS"."user_id" = "USERS"."id"
WHERE EXTRACT(YEAR FROM TO_TIMESTAMP_NTZ("ORDERS"."created_at" / 1000000)) = 2021
GROUP BY
  "Month",
  "Country",
  "Product_Department",
  "Product_Category"
ORDER BY
  "Month",
  "Country",
  "Product_Department",
  "Product_Category";