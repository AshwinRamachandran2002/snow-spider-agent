-- Which month of 2017 shows the largest absolute gap (in thousands of minutes)
-- between cumulative ride‑time minutes for Customers vs Subscribers?
WITH monthly_usage AS (
  -- 1.  Aggregate ride‑time minutes by month and rider class
  SELECT
    EXTRACT(MONTH FROM `end_date`)         AS month_num,
    `subscriber_type`,
    SUM(`duration_sec`) / 60.0             AS total_minutes   -- convert sec → min
  FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips`
  WHERE EXTRACT(YEAR FROM `end_date`) = 2017
  GROUP BY month_num, `subscriber_type`
),
pivot AS (
  -- 2.  Put the two rider classes on the same row
  SELECT
    month_num,
    SUM(CASE WHEN subscriber_type = 'Customer'   THEN total_minutes END) AS customer_minutes,
    SUM(CASE WHEN subscriber_type = 'Subscriber' THEN total_minutes END) AS subscriber_minutes
  FROM monthly_usage
  GROUP BY month_num
),
diffs AS (
  -- 3.  Compute absolute difference (expressed in thousands of minutes)
  SELECT
    month_num,
    ABS(customer_minutes - subscriber_minutes) / 1000.0 AS diff_kmins
  FROM pivot
)
-- 4.  Pick the month with the largest gap
SELECT month_num
FROM diffs
ORDER BY diff_kmins DESC, month_num
LIMIT 1;