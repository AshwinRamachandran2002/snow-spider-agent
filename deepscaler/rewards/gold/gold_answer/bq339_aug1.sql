-- Task: For each month in 2017, what are the total bike usage minutes for customers and subscribers?
SELECT
  EXTRACT(MONTH FROM `end_date`) AS `end_month`,
  SUM(CASE WHEN `subscriber_type` = 'Customer' THEN `duration_sec` / 60 ELSE 0 END) AS `customer_minutes_sum`,
  SUM(CASE WHEN `subscriber_type` = 'Subscriber' THEN `duration_sec` / 60 ELSE 0 END) AS `subscriber_minutes_sum`
FROM
  `bigquery-public-data`.`san_francisco_bikeshare`.`bikeshare_trips`
WHERE
  EXTRACT(YEAR FROM `end_date`) = 2017
GROUP BY
  `end_month`
ORDER BY
  `end_month`;