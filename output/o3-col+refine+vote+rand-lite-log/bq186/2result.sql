SELECT
  FORMAT_DATE('%Y%m', DATE(start_date))                                                     AS year_month,
  ARRAY_AGG(duration_sec ORDER BY start_date ASC  )[OFFSET(0)] / 60.0                       AS first_trip_duration_min,
  ARRAY_AGG(duration_sec ORDER BY start_date DESC )[OFFSET(0)] / 60.0                       AS last_trip_duration_min,
  MAX(duration_sec) / 60.0                                                                  AS highest_trip_duration_min,
  MIN(duration_sec) / 60.0                                                                  AS lowest_trip_duration_min
FROM `bigquery-public-data.san_francisco.bikeshare_trips`
GROUP BY year_month
ORDER BY year_month;