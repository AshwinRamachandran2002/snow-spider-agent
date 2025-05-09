SELECT
  YYYYMM,
  (ARRAY_AGG(duration_minutes ORDER BY start_date ASC LIMIT 1))[OFFSET(0)] AS first_trip_duration_minutes,
  (ARRAY_AGG(duration_minutes ORDER BY start_date DESC LIMIT 1))[OFFSET(0)] AS last_trip_duration_minutes,
  MAX(duration_minutes) AS highest_trip_duration_minutes,
  MIN(duration_minutes) AS lowest_trip_duration_minutes
FROM (
  SELECT
    FORMAT_DATE('%Y%m', DATE(start_date)) AS YYYYMM,
    duration_sec / 60.0 AS duration_minutes,
    start_date
  FROM `bigquery-public-data.san_francisco.bikeshare_trips`
)
GROUP BY YYYYMM
ORDER BY YYYYMM;