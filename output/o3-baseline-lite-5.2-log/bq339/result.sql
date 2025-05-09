WITH minutes_by_type AS (
  SELECT
    EXTRACT(MONTH FROM end_date) AS month_num,
    subscriber_type,
    SUM(duration_sec) / 60.0 AS total_minutes   -- convert seconds → minutes
  FROM
    `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips`
  WHERE
    EXTRACT(YEAR FROM end_date) = 2017
    AND subscriber_type IN ('Subscriber', 'Customer')
  GROUP BY
    month_num,
    subscriber_type
),
minutes_pivot AS (
  SELECT
    month_num,
    SUM(IF(subscriber_type = 'Subscriber', total_minutes, 0)) AS subscriber_minutes,
    SUM(IF(subscriber_type = 'Customer',  total_minutes, 0)) AS customer_minutes
  FROM
    minutes_by_type
  GROUP BY
    month_num
),
diffs AS (
  SELECT
    month_num,
    ABS(subscriber_minutes - customer_minutes) / 1000.0 AS diff_minutes_k   -- difference in thousands of minutes
  FROM
    minutes_pivot
)
SELECT
  month_num AS month_with_largest_difference
FROM
  diffs
ORDER BY
  diff_minutes_k DESC,
  month_num
LIMIT 1;