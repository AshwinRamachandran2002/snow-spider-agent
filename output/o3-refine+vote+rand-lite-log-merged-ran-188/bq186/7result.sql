SELECT
  yyyymm,
  (ARRAY_AGG(duration_min ORDER BY start_date  LIMIT 1))[OFFSET(0)] AS first_trip_minutes,
  (ARRAY_AGG(duration_min ORDER BY start_date DESC LIMIT 1))[OFFSET(0)] AS last_trip_minutes,
  MAX(duration_min) AS highest_trip_minutes,
  MIN(duration_min) AS lowest_trip_minutes
FROM (
  SELECT
    FORMAT_DATE('%Y%m', DATE(start_date))            AS yyyymm,
    start_date,
    duration_sec / 60.0                              AS duration_min
  FROM `bigquery-public-data.san_francisco.bikeshare_trips`
)
GROUP BY yyyymm
ORDER BY yyyymm;