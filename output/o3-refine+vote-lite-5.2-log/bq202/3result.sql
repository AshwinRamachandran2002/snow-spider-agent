-- Day‑of‑week (1 = Sunday … 7 = Saturday) and hour (0–23) 
-- with the most trips for the single station that had the
-- highest number of Citibike trip starts in 2018
WITH trips_2018 AS (
  SELECT
    start_station_id,
    starttime
  FROM
    `bigquery-public-data.new_york_citibike.citibike_trips`
  WHERE
    EXTRACT(YEAR FROM starttime) = 2018
    AND start_station_id IS NOT NULL
),
-- find station with the most trip starts
top_station AS (
  SELECT
    start_station_id
  FROM (
    SELECT
      start_station_id,
      COUNT(*) AS trips
    FROM trips_2018
    GROUP BY start_station_id
    ORDER BY trips DESC, start_station_id
    LIMIT 1
  )
),
-- all 2018 trips that started at that station
station_trips AS (
  SELECT t.starttime
  FROM trips_2018 t
  JOIN top_station s
  ON t.start_station_id = s.start_station_id
),
-- most‑popular day of week
top_dow AS (
  SELECT
    EXTRACT(DAYOFWEEK FROM starttime) AS day_of_week
  FROM station_trips
  GROUP BY day_of_week
  ORDER BY COUNT(*) DESC, day_of_week
  LIMIT 1
),
-- most‑popular hour of day
top_hour AS (
  SELECT
    EXTRACT(HOUR FROM starttime) AS hour_of_day
  FROM station_trips
  GROUP BY hour_of_day
  ORDER BY COUNT(*) DESC, hour_of_day
  LIMIT 1
)
SELECT
  d.day_of_week,
  h.hour_of_day
FROM top_dow d
CROSS JOIN top_hour h;