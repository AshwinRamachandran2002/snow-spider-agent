SELECT
  FORMAT_DATE('%B %Y', DATE(2017, month, 1)) AS Month,
  ROUND(absolute_difference_in_minutes,4) AS Absolute_Difference_in_Minutes
FROM (
  SELECT
    EXTRACT(MONTH FROM start_date) AS month,
    ABS(
      SUM(CASE WHEN subscriber_type = 'Customer' THEN duration_sec ELSE 0 END)/60 -
      SUM(CASE WHEN subscriber_type = 'Subscriber' THEN duration_sec ELSE 0 END)/60
    ) AS absolute_difference_in_minutes
  FROM
    `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips`
  WHERE
    EXTRACT(YEAR FROM start_date) = 2017
    AND subscriber_type IN ('Customer', 'Subscriber')
  GROUP BY
    month
)
ORDER BY
  absolute_difference_in_minutes DESC
LIMIT 1;