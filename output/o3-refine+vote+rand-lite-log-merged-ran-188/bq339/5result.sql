WITH monthly_minutes AS (
  SELECT
    EXTRACT(MONTH FROM end_date) AS month_num,
    subscriber_type,
    SUM(duration_sec) / 60.0 / 1000.0 AS minutes_k   -- minutes in thousands
  FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips`
  WHERE EXTRACT(YEAR FROM end_date) = 2017          -- only trips that ended in 2017
    AND subscriber_type IN ('Customer', 'Subscriber')
  GROUP BY month_num, subscriber_type
),
pivoted AS (
  SELECT
    month_num,
    MAX(IF(subscriber_type = 'Customer',   minutes_k, NULL)) AS customer_min_k,
    MAX(IF(subscriber_type = 'Subscriber', minutes_k, NULL)) AS subscriber_min_k
  FROM monthly_minutes
  GROUP BY month_num
),
diffs AS (
  SELECT
    month_num,
    ABS(customer_min_k - subscriber_min_k) AS abs_diff_k
  FROM pivoted
)
SELECT
  month_num
FROM diffs
ORDER BY abs_diff_k DESC
LIMIT 1;