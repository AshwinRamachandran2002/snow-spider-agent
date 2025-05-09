SELECT
  year_month,
  ROUND((ARRAY_AGG(duration_sec / 60.0 ORDER BY start_date ASC LIMIT 1))[OFFSET(0)], 4) AS first_trip_duration_minutes,
  ROUND((ARRAY_AGG(duration_sec / 60.0 ORDER BY start_date DESC LIMIT 1))[OFFSET(0)], 4) AS last_trip_duration_minutes,
  ROUND(MAX(duration_sec / 60.0), 4) AS highest_trip_duration_minutes,
  ROUND(MIN(duration_sec / 60.0), 4) AS lowest_trip_duration_minutes
FROM (
  SELECT
    FORMAT_TIMESTAMP('%Y%m', start_date) AS year_month,
    start_date,
    duration_sec
  FROM `bigquery-public-data.san_francisco.bikeshare_trips`
)
GROUP BY year_month
ORDER BY year_month;