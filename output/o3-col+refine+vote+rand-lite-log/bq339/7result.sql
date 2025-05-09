-- Month of 2017 with the greatest absolute difference (in thousands of minutes)
-- between Customer and Subscriber cumulative bike-usage minutes
SELECT month_num
FROM (
  SELECT
    EXTRACT(MONTH FROM end_date)                                       AS month_num,
    SUM(CASE WHEN subscriber_type = 'Customer'   THEN duration_sec END) / 60.0 / 1000 AS customer_minutes_k,
    SUM(CASE WHEN subscriber_type = 'Subscriber' THEN duration_sec END) / 60.0 / 1000 AS subscriber_minutes_k
  FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips`
  WHERE EXTRACT(YEAR FROM end_date) = 2017
  GROUP BY month_num
)
ORDER BY ABS(customer_minutes_k - subscriber_minutes_k) DESC
LIMIT 1;