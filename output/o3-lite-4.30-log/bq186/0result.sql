SELECT
  FORMAT_TIMESTAMP('%Y%m', start_date)                                                         AS year_month,
  ROUND(ARRAY_AGG(duration_sec ORDER BY start_date            LIMIT 1)[OFFSET(0)] / 60.0, 4)   AS first_trip_duration_min,
  ROUND(ARRAY_AGG(duration_sec ORDER BY start_date DESC       LIMIT 1)[OFFSET(0)] / 60.0, 4)   AS last_trip_duration_min,
  ROUND(MAX(duration_sec) / 60.0, 4)                                                            AS max_trip_duration_min,
  ROUND(MIN(duration_sec) / 60.0, 4)                                                            AS min_trip_duration_min
FROM `bigquery-public-data.san_francisco.bikeshare_trips`
GROUP BY year_month
ORDER BY year_month;