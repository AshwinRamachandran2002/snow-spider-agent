WITH monthly AS (
  SELECT
    EXTRACT(MONTH FROM end_date) AS month_num,
    SUM(CASE WHEN subscriber_type = 'Customer'   THEN duration_sec END)/60/1000 AS customer_kmin,
    SUM(CASE WHEN subscriber_type = 'Subscriber' THEN duration_sec END)/60/1000 AS subscriber_kmin
  FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips`
  WHERE EXTRACT(YEAR FROM end_date) = 2017
    AND subscriber_type IN ('Customer','Subscriber')
  GROUP BY month_num
)
SELECT
  month_num AS month,
  ROUND(ABS(subscriber_kmin - customer_kmin), 4) AS difference_usage_minutes_thousands
FROM monthly
ORDER BY difference_usage_minutes_thousands DESC, month
LIMIT 1;