-- Task: List the total profit from Facebook-sourced completed orders for each month from August 2022 to November 2023. Calculate profit as sales minus costs.

WITH 
orders AS (
  SELECT
    "order_id", 
    "user_id", 
    "created_at",
    DATE_TRUNC('MONTH', TO_TIMESTAMP_NTZ("delivered_at" / 1000000)) AS "delivery_month",
    "status" 
  FROM "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDERS"
),
order_items AS (
  SELECT 
    "order_id", 
    "product_id", 
    "sale_price" 
  FROM "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS"
),
products AS (
  SELECT 
    "id", 
    "cost"
  FROM "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."PRODUCTS"
),
users AS (
  SELECT
    "id", 
    "traffic_source" 
  FROM "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."USERS"
),
filter_join AS (
  SELECT 
    orders."order_id",
    orders."user_id",
    order_items."product_id",
    orders."delivery_month",
    order_items."sale_price",
    products."cost",
    users."traffic_source"
  FROM orders
  JOIN order_items ON orders."order_id" = order_items."order_id"
  JOIN products ON order_items."product_id" = products."id"
  JOIN users ON orders."user_id" = users."id"
  WHERE orders."status" = 'Complete' 
    AND users."traffic_source" = 'Facebook'
    AND orders."delivery_month" BETWEEN '2022-08-01' AND '2023-11-30'
)
SELECT 
  "delivery_month",
  SUM("sale_price") - SUM("cost") AS "total_profit"
FROM filter_join
GROUP BY "delivery_month"
ORDER BY "delivery_month";