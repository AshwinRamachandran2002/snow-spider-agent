WITH monthly_counts AS (
  SELECT
    `company`,
    EXTRACT(MONTH FROM `trip_start_timestamp`) AS month,
    COUNT(*) AS trip_count
  FROM `bigquery-public-data`.chicago_taxi_trips.taxi_trips
  WHERE EXTRACT(YEAR FROM `trip_start_timestamp`) = 2018
  GROUP BY `company`, month
)
SELECT
  curr.`company`,
  prev.month AS From_Month,
  curr.month AS To_Month,
  (curr.trip_count - prev.trip_count) AS Trip_Increase
FROM monthly_counts AS curr
JOIN monthly_counts AS prev
  ON curr.`company` = prev.`company`
  AND curr.month = prev.month + 1
ORDER BY Trip_Increase DESC
LIMIT 3;