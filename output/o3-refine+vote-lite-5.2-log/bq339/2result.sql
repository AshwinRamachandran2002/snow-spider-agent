WITH monthly_usage AS (
  SELECT
    EXTRACT(MONTH FROM `end_date`) AS month_number,
    SUM(CASE WHEN subscriber_type = 'Customer'   THEN duration_sec/60.0 ELSE 0 END) AS customer_minutes,
    SUM(CASE WHEN subscriber_type = 'Subscriber' THEN duration_sec/60.0 ELSE 0 END) AS subscriber_minutes
  FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips`
  WHERE EXTRACT(YEAR FROM `end_date`) = 2017
  GROUP BY month_number
),
diffs AS (
  SELECT
    month_number,
    ABS(customer_minutes - subscriber_minutes)/1000 AS diff_thousand_minutes
  FROM monthly_usage
)
SELECT month_number
FROM diffs
ORDER BY diff_thousand_minutes DESC
LIMIT 1;