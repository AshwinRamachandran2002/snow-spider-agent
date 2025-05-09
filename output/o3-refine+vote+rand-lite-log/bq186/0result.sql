SELECT
  year_month,
  ARRAY_AGG(duration_min ORDER BY start_date ASC)[OFFSET(0)]  AS first_trip_duration_min,
  ARRAY_AGG(duration_min ORDER BY start_date DESC)[OFFSET(0)] AS last_trip_duration_min,
  MAX(duration_min)                                           AS highest_trip_duration_min,
  MIN(duration_min)                                           AS lowest_trip_duration_min
FROM (
  SELECT
    FORMAT_TIMESTAMP('%Y%m', start_date)      AS year_month,
    start_date,
    ROUND(duration_sec / 60.0, 4)             AS duration_min
  FROM `bigquery-public-data.san_francisco.bikeshare_trips`
)
GROUP BY year_month
ORDER BY year_month;