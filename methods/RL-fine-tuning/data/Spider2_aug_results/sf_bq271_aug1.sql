-- Task: Please generate a report that, for each month in 2021, provides the number of orders and the total sale price of items sold during that month.
SELECT 
  DATE_TRUNC('MONTH', TO_DATE(TO_TIMESTAMP_NTZ(orders."created_at" / 1000000))) AS "reporting_month",
  COUNT(DISTINCT orders."order_id") AS "n_orders",
  SUM(order_items."sale_price") AS "total_sale_price"
FROM "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDERS" AS orders
LEFT JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS" AS order_items
  ON orders."order_id" = order_items."order_id"
WHERE TO_TIMESTAMP_NTZ(orders."created_at" / 1000000) BETWEEN TO_TIMESTAMP_NTZ('2021-01-01') AND TO_TIMESTAMP_NTZ('2021-12-31')
GROUP BY 1
ORDER BY "reporting_month";