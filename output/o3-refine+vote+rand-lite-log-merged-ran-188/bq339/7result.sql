WITH monthly_totals AS (
  SELECT
    EXTRACT(MONTH FROM end_date) AS month,
    -- convert seconds to minutes, then to thousands of minutes
    SUM(CASE WHEN subscriber_type = 'Customer'   THEN duration_sec/60.0 END)/1000 AS cust_minutes_k,
    SUM(CASE WHEN subscriber_type = 'Subscriber' THEN duration_sec/60.0 END)/1000 AS sub_minutes_k
  FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips`
  WHERE EXTRACT(YEAR  FROM end_date) = 2017
    AND subscriber_type IN ('Customer','Subscriber')
  GROUP BY month
)
SELECT
  month
FROM (
  SELECT
    month,
    ABS(cust_minutes_k - sub_minutes_k) AS abs_diff_k
  FROM monthly_totals
)
ORDER BY abs_diff_k DESC
LIMIT 1;