SELECT
  CONCAT(FORMAT_DATE('%B', DATE(start_date)), ' ', EXTRACT(YEAR FROM start_date)) AS Month,
  ROUND(ABS(
    SUM(CASE WHEN subscriber_type = 'Subscriber' THEN duration_sec / 60 ELSE 0 END) -
    SUM(CASE WHEN subscriber_type = 'Customer' THEN duration_sec / 60 ELSE 0 END)
  ), 4) AS Absolute_Difference_in_Minutes
FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips`
WHERE EXTRACT(YEAR FROM start_date) = 2017
  AND subscriber_type IN ('Subscriber', 'Customer')
GROUP BY EXTRACT(YEAR FROM start_date), EXTRACT(MONTH FROM start_date), Month
ORDER BY Absolute_Difference_in_Minutes DESC
LIMIT 1;