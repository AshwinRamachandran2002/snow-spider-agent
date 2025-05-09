SELECT
  FORMAT_DATE('%Y%m', DATE(start_date)) AS yyyymm,
  ROUND(ARRAY_AGG(duration_sec ORDER BY start_date ASC )[OFFSET(0)] / 60, 2) AS first_trip_min,
  ROUND(ARRAY_AGG(duration_sec ORDER BY start_date DESC)[OFFSET(0)] / 60, 2) AS last_trip_min,
  ROUND(MAX(duration_sec) / 60, 2)                                           AS highest_trip_min,
  ROUND(MIN(duration_sec) / 60, 2)                                           AS lowest_trip_min
FROM `bigquery-public-data.san_francisco.bikeshare_trips`
GROUP BY yyyymm
ORDER BY yyyymm;