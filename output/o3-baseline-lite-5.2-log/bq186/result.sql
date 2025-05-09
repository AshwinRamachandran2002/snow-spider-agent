--  Year‑month level trip‑duration summary for San‑Francisco bike‑share trips
WITH trips_sf AS (
  SELECT
    t.trip_id,
    t.duration_sec,
    t.start_date,
    FORMAT_DATE('%Y%m', DATE(t.start_date)) AS year_month
  FROM `bigquery-public-data.san_francisco.bikeshare_trips`   AS t
  JOIN `bigquery-public-data.san_francisco.bikeshare_stations` AS s
    ON t.start_station_id = s.station_id
  WHERE s.landmark = 'San Francisco'          -- keep only SF trips
)

SELECT
  year_month,
  -- first trip (earliest start_date) duration in minutes
  ARRAY_AGG(duration_sec ORDER BY start_date, trip_id LIMIT 1)[OFFSET(0)] / 60.0
    AS first_trip_minutes,
  -- last trip (latest start_date) duration in minutes
  ARRAY_AGG(duration_sec ORDER BY start_date DESC, trip_id DESC LIMIT 1)[OFFSET(0)] / 60.0
    AS last_trip_minutes,
  MAX(duration_sec) / 60.0  AS highest_trip_minutes,
  MIN(duration_sec) / 60.0  AS lowest_trip_minutes
FROM trips_sf
GROUP BY year_month
ORDER BY year_month;