WITH month_totals AS (
  SELECT
    EXTRACT(MONTH FROM end_date) AS month_num,
    SUM(CASE WHEN subscriber_type = 'Customer'   THEN duration_sec ELSE 0 END) AS customer_sec,
    SUM(CASE WHEN subscriber_type = 'Subscriber' THEN duration_sec ELSE 0 END) AS subscriber_sec
  FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips`
  WHERE EXTRACT(YEAR FROM end_date) = 2017
  GROUP BY month_num
)
SELECT
  month_num AS month_number,
  ABS(customer_sec - subscriber_sec) / 60.0 / 1000 AS abs_diff_thousand_minutes
FROM month_totals
ORDER BY abs_diff_thousand_minutes DESC
LIMIT 1;