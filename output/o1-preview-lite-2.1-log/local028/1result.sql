WITH months AS (
  SELECT '01' AS month_number, 'Jan' AS Month UNION ALL
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
),
orders_2016 AS (
  SELECT
    strftime('%m', order_delivered_customer_date) AS month_number,
    COUNT(*) AS delivered_orders
  FROM olist_orders
  WHERE order_status = 'delivered' AND strftime('%Y', order_delivered_customer_date) = '2016'
  GROUP BY month_number
),
orders_2017 AS (
  SELECT
    strftime('%m', order_delivered_customer_date) AS month_number,
    COUNT(*) AS delivered_orders
  FROM olist_orders
  WHERE order_status = 'delivered' AND strftime('%Y', order_delivered_customer_date) = '2017'
  GROUP BY month_number
),
orders_2018 AS (
  SELECT
    strftime('%m', order_delivered_customer_date) AS month_number,
    COUNT(*) AS delivered_orders
  FROM olist_orders
  WHERE order_status = 'delivered' AND strftime('%Y', order_delivered_customer_date) = '2018'
  GROUP BY month_number
)
SELECT
  months.Month,
  COALESCE(orders_2016.delivered_orders, 0) AS "2016",
  COALESCE(orders_2017.delivered_orders, 0) AS "2017",
  COALESCE(orders_2018.delivered_orders, 0) AS "2018"
FROM months
LEFT JOIN orders_2016 ON months.month_number = orders_2016.month_number
LEFT JOIN orders_2017 ON months.month_number = orders_2017.month_number
LEFT JOIN orders_2018 ON months.month_number = orders_2018.month_number
ORDER BY CAST(months.month_number AS INTEGER);