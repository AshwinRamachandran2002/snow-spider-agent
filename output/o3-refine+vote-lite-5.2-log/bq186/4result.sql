SELECT
  year_month,
  -- first trip duration (earliest trip of the month)
  (ARRAY_AGG(duration_min ORDER BY start_date ASC LIMIT 1))[OFFSET(0)] AS first_trip_duration_min,
  -- last trip duration (latest trip of the month)
  (ARRAY_AGG(duration_min ORDER BY start_date DESC LIMIT 1))[OFFSET(0)] AS last_trip_duration_min,
  -- highest trip duration in the month
  MAX(duration_min)  AS highest_trip_duration_min,
  -- lowest trip duration in the month
  MIN(duration_min)  AS lowest_trip_duration_min
FROM (
  SELECT
    FORMAT_DATE('%Y%m', DATE(t.start_date))            AS year_month,
    t.duration_sec / 60.0                              AS duration_min,
    t.start_date
  FROM `bigquery-public-data.san_francisco.bikeshare_trips`    AS t
  JOIN `bigquery-public-data.san_francisco.bikeshare_stations` AS s
    ON t.start_station_id = s.station_id
  WHERE s.landmark = 'San Francisco'         -- keep only trips that start in San Francisco
)
GROUP BY year_month
ORDER BY year_month;