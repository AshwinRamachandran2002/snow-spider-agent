WITH trips AS (
  SELECT
    FORMAT_TIMESTAMP('%Y%m', `start_date`) AS year_month,
    `start_date`,
    `duration_sec` / 60.0 AS duration_min
  FROM `bigquery-public-data.san_francisco.bikeshare_trips`
)

SELECT
  year_month,
  (ARRAY_AGG(duration_min ORDER BY start_date ASC  LIMIT 1))[OFFSET(0)]  AS first_trip_min,
  (ARRAY_AGG(duration_min ORDER BY start_date DESC LIMIT 1))[OFFSET(0)] AS last_trip_min,
  MAX(duration_min) AS highest_trip_min,
  MIN(duration_min) AS lowest_trip_min
FROM trips
GROUP BY year_month
ORDER BY year_month;