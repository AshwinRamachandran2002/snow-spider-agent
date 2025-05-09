WITH sf_trips AS (
  SELECT
    FORMAT_TIMESTAMP('%Y%m', t.start_date)          AS year_month,
    t.start_date,
    t.duration_sec / 60.0                          AS duration_min
  FROM `bigquery-public-data.san_francisco.bikeshare_trips`   AS t
  JOIN `bigquery-public-data.san_francisco.bikeshare_stations` AS s
        ON t.start_station_id = s.station_id
  WHERE s.landmark = 'San Francisco'
)
SELECT
  year_month,
  ARRAY_AGG(duration_min ORDER BY start_date ASC  LIMIT 1)[OFFSET(0)] AS first_duration_minutes,
  ARRAY_AGG(duration_min ORDER BY start_date DESC LIMIT 1)[OFFSET(0)] AS last_duration_minutes,
  MAX(duration_min)                                                   AS highest_duration_minutes,
  MIN(duration_min)                                                   AS lowest_duration_minutes
FROM sf_trips
GROUP BY year_month
ORDER BY year_month;