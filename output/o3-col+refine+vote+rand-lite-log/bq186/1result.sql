WITH trips AS (
  SELECT
    FORMAT_TIMESTAMP('%Y%m', start_date) AS yyyymm,
    start_date,
    CAST(duration_sec / 60 AS INT64) AS duration_min
  FROM `bigquery-public-data.san_francisco.bikeshare_trips`
)

SELECT
  yyyymm,
  ARRAY_AGG(duration_min ORDER BY start_date ASC  LIMIT 1)[OFFSET(0)]  AS first_trip_duration_min,
  ARRAY_AGG(duration_min ORDER BY start_date DESC LIMIT 1)[OFFSET(0)] AS last_trip_duration_min,
  MAX(duration_min) AS highest_trip_duration_min,
  MIN(duration_min) AS lowest_trip_duration_min
FROM trips
GROUP BY yyyymm
ORDER BY yyyymm;