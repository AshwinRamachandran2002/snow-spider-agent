SELECT
  month_names.month_name AS Month,
  COALESCE(SUM(CASE WHEN year = '2016' THEN num_orders END), 0) AS "2016",
  COALESCE(SUM(CASE WHEN year = '2017' THEN num_orders END), 0) AS "2017",
  COALESCE(SUM(CASE WHEN year = '2018' THEN num_orders END), 0) AS "2018"
FROM (
  SELECT '01' AS month_number, 'Jan' AS month_name UNION ALL
  SELECT '02', 'Feb' UNION ALL
  SELECT '03', 'Mar' UNION ALL
  SELECT '04', 'Apr' UNION ALL
  SELECT '05', 'May' UNION ALL
  SELECT '06', 'Jun' UNION ALL
  SELECT '07', 'Jul' UNION ALL
  SELECT '08', 'Aug' UNION ALL
  SELECT '09', 'Sep' UNION ALL
  SELECT '10', 'Oct' UNION ALL
  SELECT '11', 'Nov' UNION ALL
  SELECT '12', 'Dec'
) AS month_names
LEFT JOIN (
  SELECT
    SUBSTR("order_delivered_customer_date", 1, 4) AS year,
    SUBSTR("order_delivered_customer_date", 6, 2) AS month_number,
    COUNT("order_id") AS num_orders
  FROM "olist_orders"
  WHERE "order_status" = 'delivered'
    AND SUBSTR("order_delivered_customer_date", 1, 4) IN ('2016', '2017', '2018')
  GROUP BY year, month_number
) AS order_data
ON month_names.month_number = order_data.month_number
GROUP BY month_names.month_number, month_names.month_name
ORDER BY CAST(month_names.month_number AS INTEGER);