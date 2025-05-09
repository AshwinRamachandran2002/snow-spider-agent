WITH monthly_totals AS (
  -- total ride-minutes for each month and user type in 2017
  SELECT
    EXTRACT(MONTH FROM end_date) AS month_num,
    subscriber_type,
    SUM(duration_sec) / 60.0 AS total_minutes
  FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips`
  WHERE EXTRACT(YEAR FROM end_date) = 2017
    AND subscriber_type IN ('Customer', 'Subscriber')
  GROUP BY month_num, subscriber_type
),
pivoted AS (
  -- put customer and subscriber totals on the same row
  SELECT
    month_num,
    SUM(CASE WHEN subscriber_type = 'Customer'   THEN total_minutes END) AS customer_minutes,
    SUM(CASE WHEN subscriber_type = 'Subscriber' THEN total_minutes END) AS subscriber_minutes
  FROM monthly_totals
  GROUP BY month_num
),
ranked AS (
  -- rank months by absolute difference
  SELECT
    month_num,
    ABS(customer_minutes - subscriber_minutes) AS diff_minutes,
    ROW_NUMBER() OVER (ORDER BY ABS(customer_minutes - subscriber_minutes) DESC) AS rn
  FROM pivoted
)
SELECT
  month_num AS biggest_diff_month_number
FROM ranked
WHERE rn = 1;