SELECT driver_id, AVG(daily_deliveries) AS average_daily_deliveries
FROM (
  SELECT d.driver_id, o.order_created_year, o.order_created_month, o.order_created_day,
         COUNT(*) AS daily_deliveries
  FROM deliveries AS d
  JOIN orders AS o ON d.delivery_order_id = o.order_id
  WHERE d.driver_id IS NOT NULL
  GROUP BY d.driver_id, o.order_created_year, o.order_created_month, o.order_created_day
) AS sub
GROUP BY driver_id
ORDER BY average_daily_deliveries DESC
LIMIT 5;