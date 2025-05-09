SELECT
  FORMAT_DATE('%B %Y', DATE(2017, month, 1)) AS Month,
  ROUND(ABS(customer_minutes - subscriber_minutes), 4) AS Absolute_Difference_in_Minutes
FROM (
  SELECT
    EXTRACT(MONTH FROM start_date) AS month,
    SUM(CASE WHEN subscriber_type = 'Customer' THEN duration_sec ELSE 0 END) / 60 AS customer_minutes,
    SUM(CASE WHEN subscriber_type = 'Subscriber' THEN duration_sec ELSE 0 END) / 60 AS subscriber_minutes
  FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips`
  WHERE EXTRACT(YEAR FROM start_date) = 2017
  GROUP BY month
)
ORDER BY Absolute_Difference_in_Minutes DESC
LIMIT 1;