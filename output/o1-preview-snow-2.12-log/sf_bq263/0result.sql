SELECT DATE_TRUNC('month', TO_TIMESTAMP(o."created_at" / 1e6)) AS "Month",
       SUM(oi."sale_price") AS "Total_Sales",
       SUM(p."cost") AS "Total_Cost",
       COUNT(DISTINCT o."order_id") AS "Number_of_Complete_Orders",
       SUM(oi."sale_price" - p."cost") AS "Total_Profit",
       ROUND(SUM(oi."sale_price" - p."cost") / NULLIF(SUM(p."cost"), 0), 4) AS "Profit_to_Cost_Ratio"
FROM "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDERS" o
JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS" oi
  ON o."order_id" = oi."order_id"
JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."PRODUCTS" p
  ON oi."product_id" = p."id"
WHERE o."status" = 'Complete'
  AND TO_TIMESTAMP(o."created_at" / 1e6) BETWEEN '2023-01-01' AND '2023-12-31 23:59:59'
  AND p."category" = 'Sleep & Lounge'
GROUP BY "Month"
ORDER BY "Month";