WITH month_totals AS (
  SELECT
    EXTRACT(MONTH FROM end_date) AS month_num,
    SUM(CASE WHEN subscriber_type = 'Customer'   THEN duration_sec ELSE 0 END) AS customer_seconds,
    SUM(CASE WHEN subscriber_type = 'Subscriber' THEN duration_sec ELSE 0 END) AS subscriber_seconds
  FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips`
  WHERE EXTRACT(YEAR FROM end_date) = 2017
  GROUP BY month_num
),
month_diffs AS (
  SELECT
    month_num,
    -- convert the absolute difference to minutes, then to thousands of minutes
    ABS(customer_seconds - subscriber_seconds) / 60.0 / 1000.0 AS diff_k_minutes
  FROM month_totals
)
SELECT
  month_num AS month_with_max_diff
FROM month_diffs
ORDER BY diff_k_minutes DESC
LIMIT 1;