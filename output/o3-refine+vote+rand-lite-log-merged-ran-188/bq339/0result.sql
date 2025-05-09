-- month_with_max_usage_minutes_difference_2017.sql
WITH monthly_minutes AS (
  SELECT
    EXTRACT(MONTH FROM end_date)                         AS month,
    SUM(CASE WHEN subscriber_type = 'Customer'   THEN duration_sec ELSE 0 END) / 60.0 AS customer_minutes,
    SUM(CASE WHEN subscriber_type = 'Subscriber' THEN duration_sec ELSE 0 END) / 60.0 AS subscriber_minutes
  FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips`
  WHERE EXTRACT(YEAR FROM end_date) = 2017              -- only trips ending in 2017
  GROUP BY month
)
SELECT
  month,                                                -- month number (1–12)
  ABS(customer_minutes - subscriber_minutes)/1000 AS diff_minutes_thousands
FROM monthly_minutes
ORDER BY diff_minutes_thousands DESC
LIMIT 1;