WITH minutes_per_month AS (
  SELECT
    EXTRACT(MONTH FROM end_date) AS month,
    -- convert seconds to minutes, then to thousands
    SUM(CASE WHEN subscriber_type = 'Customer'   THEN duration_sec/60.0 END)/1000 AS customer_min_k,
    SUM(CASE WHEN subscriber_type = 'Subscriber' THEN duration_sec/60.0 END)/1000 AS subscriber_min_k
  FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips`
  WHERE EXTRACT(YEAR FROM end_date) = 2017
  GROUP BY month
),
diffs AS (
  SELECT
    month,
    ABS(customer_min_k - subscriber_min_k) AS abs_diff_k
  FROM minutes_per_month
)
SELECT month
FROM diffs
ORDER BY abs_diff_k DESC, month
LIMIT 1;