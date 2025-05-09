WITH monthly_minutes AS (
  SELECT
    EXTRACT(MONTH FROM end_date) AS month_num,
    SUM(CASE WHEN subscriber_type = 'Customer'   THEN duration_sec ELSE 0 END) / 60.0 / 1000 AS cust_thous_min,
    SUM(CASE WHEN subscriber_type = 'Subscriber' THEN duration_sec ELSE 0 END) / 60.0 / 1000 AS sub_thous_min
  FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips`
  WHERE EXTRACT(YEAR FROM end_date) = 2017
  GROUP BY month_num
)
SELECT month_num
FROM (
  SELECT
    month_num,
    ABS(cust_thous_min - sub_thous_min) AS abs_diff_thous_min
  FROM monthly_minutes
)
ORDER BY abs_diff_thous_min DESC
LIMIT 1;