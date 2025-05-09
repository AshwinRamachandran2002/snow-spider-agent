SELECT
  strftime('%m', order_purchase_timestamp) AS month,
  SUM(CASE WHEN strftime('%Y', order_purchase_timestamp) = '2016' THEN 1 ELSE 0 END) AS "2016",
  SUM(CASE WHEN strftime('%Y', order_purchase_timestamp) = '2017' THEN 1 ELSE 0 END) AS "2017",
  SUM(CASE WHEN strftime('%Y', order_purchase_timestamp) = '2018' THEN 1 ELSE 0 END) AS "2018"
FROM olist_orders
WHERE order_status = 'delivered'
  AND strftime('%Y', order_purchase_timestamp) IN ('2016', '2017', '2018')
GROUP BY month
ORDER BY month;