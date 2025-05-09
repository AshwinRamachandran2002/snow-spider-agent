-- Month in 2017 with the largest absolute difference (in thousands of minutes)
-- between cumulative bike-usage minutes for Customers and Subscribers
WITH trip_minutes AS (
  SELECT
    EXTRACT(MONTH FROM end_date) AS month_num,
    subscriber_type,
    duration_sec
  FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips`
  WHERE EXTRACT(YEAR FROM end_date) = 2017
),
pivot_totals AS (
  SELECT
    month_num,
    SUM(IF(subscriber_type = 'Customer',   duration_sec, 0))/60.0 AS customer_minutes,
    SUM(IF(subscriber_type = 'Subscriber', duration_sec, 0))/60.0 AS subscriber_minutes
  FROM trip_minutes
  GROUP BY month_num
),
diffs AS (
  SELECT
    month_num,
    ABS(customer_minutes - subscriber_minutes)/1000.0 AS gap_kmins
  FROM pivot_totals
)
SELECT
  month_num AS month_with_largest_gap,
  ROUND(gap_kmins, 1) AS gap_kmins
FROM diffs
ORDER BY gap_kmins DESC
LIMIT 1;