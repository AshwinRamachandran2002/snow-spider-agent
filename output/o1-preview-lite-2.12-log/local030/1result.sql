SELECT AVG(total_payments) AS Average_Total_Payments,
       AVG(delivered_order_count) AS Average_Total_Delivered_Order_Counts
FROM (
  SELECT c."customer_city",
         SUM(p."payment_value") AS total_payments,
         COUNT(o."order_id") AS delivered_order_count
  FROM "olist_orders" o
  JOIN "olist_order_payments" p ON o."order_id" = p."order_id"
  JOIN "olist_customers" c ON o."customer_id" = c."customer_id"
  WHERE o."order_status" = 'delivered'
  GROUP BY c."customer_city"
  ORDER BY total_payments ASC
  LIMIT 5
) AS bottom_cities;