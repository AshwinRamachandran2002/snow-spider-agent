WITH sf_trips AS (
  SELECT
    bt.start_date,
    bt.duration_sec / 60.0 AS duration_min
  FROM `bigquery-public-data.san_francisco.bikeshare_trips`  AS bt
  JOIN `bigquery-public-data.san_francisco.bikeshare_stations` AS bs
    ON bt.start_station_id = bs.station_id
  WHERE bs.landmark = 'San Francisco'
)
SELECT
  FORMAT_DATE('%Y%m', DATE(start_date))                                                         AS year_month,
  ROUND(ARRAY_AGG(duration_min ORDER BY start_date ASC  LIMIT 1)[OFFSET(0)], 4)                 AS first_trip_duration_min,
  ROUND(ARRAY_AGG(duration_min ORDER BY start_date DESC LIMIT 1)[OFFSET(0)], 4)                 AS last_trip_duration_min,
  ROUND(MAX(duration_min), 4)                                                                   AS max_trip_duration_min,
  ROUND(MIN(duration_min), 4)                                                                   AS min_trip_duration_min
FROM sf_trips
GROUP BY year_month
ORDER BY year_month;