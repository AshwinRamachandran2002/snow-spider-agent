WITH trips_2017 AS (
  -- keep only trips whose **end** occurred in 2017
  SELECT
    end_date,
    duration_sec,
    subscriber_type
  FROM
    `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips`
  WHERE
    EXTRACT(YEAR FROM end_date) = 2017
),
monthly_totals AS (
  -- total (cumulative) usage minutes per month and rider class,
  -- then put the figure in thousands of minutes
  SELECT
    EXTRACT(MONTH FROM end_date) AS month_num,
    -- minutes → divide by 60, thousands → divide by 1 000
    SUM(CASE WHEN subscriber_type = 'Customer'   THEN duration_sec END) / 60.0 / 1000 AS customer_min_k,
    SUM(CASE WHEN subscriber_type = 'Subscriber' THEN duration_sec END) / 60.0 / 1000 AS subscriber_min_k
  FROM
    trips_2017
  GROUP BY
    month_num
),
month_diff AS (
  SELECT
    month_num,
    ABS(customer_min_k - subscriber_min_k) AS abs_diff_k
  FROM
    monthly_totals
)
SELECT
  month_num AS month_with_largest_difference
FROM
  month_diff
ORDER BY
  abs_diff_k DESC
LIMIT 1;