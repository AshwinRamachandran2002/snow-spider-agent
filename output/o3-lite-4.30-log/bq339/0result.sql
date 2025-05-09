WITH customer_subscriber_month AS (
  SELECT
    EXTRACT(MONTH FROM end_date) AS month,
    subscriber_type,
    SUM(duration_sec) / 60.0 / 1000 AS usage_minutes_thousands
  FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips`
  WHERE EXTRACT(YEAR FROM end_date) = 2017
    AND subscriber_type IN ('Customer', 'Subscriber')
  GROUP BY month, subscriber_type
),
diffs AS (
  SELECT
    month,
    ABS(SUM(CASE
              WHEN subscriber_type = 'Customer'   THEN  usage_minutes_thousands
              WHEN subscriber_type = 'Subscriber' THEN -usage_minutes_thousands
            END)) AS difference_usage_minutes_thousands
  FROM customer_subscriber_month
  GROUP BY month
)
SELECT
  month,
  ROUND(difference_usage_minutes_thousands, 4) AS difference_usage_minutes_thousands
FROM diffs
ORDER BY difference_usage_minutes_thousands DESC, month
LIMIT 1;