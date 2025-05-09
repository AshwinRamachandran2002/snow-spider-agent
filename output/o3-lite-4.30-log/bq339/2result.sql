SELECT
  month_num AS month,
  ROUND(ABS(subscriber_kmins - customer_kmins), 4) AS difference_usage_minutes_thousands
FROM (
  SELECT
    EXTRACT(MONTH FROM `end_date`) AS month_num,
    SUM(CASE WHEN subscriber_type = 'Customer'   THEN duration_sec END) / 60.0 / 1000 AS customer_kmins,
    SUM(CASE WHEN subscriber_type = 'Subscriber' THEN duration_sec END) / 60.0 / 1000 AS subscriber_kmins
  FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips`
  WHERE EXTRACT(YEAR FROM `end_date`) = 2017
  GROUP BY month_num
)
ORDER BY difference_usage_minutes_thousands DESC, month_num
LIMIT 1;