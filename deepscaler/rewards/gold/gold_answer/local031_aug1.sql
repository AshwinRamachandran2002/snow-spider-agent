-- Task: Find the year among 2016, 2017, and 2018 with the lowest number of delivered orders.
SELECT strftime('%Y', "order_delivered_customer_date") AS "Year", COUNT("order_id") AS Delivered_Orders
FROM "olist_orders"
WHERE "order_status" = 'delivered'
  AND strftime('%Y', "order_delivered_customer_date") IN ('2016', '2017', '2018')
  AND "order_delivered_customer_date" IS NOT NULL
GROUP BY "Year"
ORDER BY Delivered_Orders ASC
LIMIT 1;