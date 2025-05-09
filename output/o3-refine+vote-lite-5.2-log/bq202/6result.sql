WITH trips_2018 AS (
  SELECT
    start_station_id,
    starttime
  FROM `bigquery-public-data.new_york_citibike.citibike_trips`
  WHERE EXTRACT(YEAR FROM starttime) = 2018
),
-- identify the station with the most trip starts in 2018
top_station AS (
  SELECT
    start_station_id
  FROM trips_2018
  GROUP BY start_station_id
  ORDER BY COUNT(*) DESC
  LIMIT 1
),
-- all 2018 trips that started at that station
station_trips AS (
  SELECT
    t.starttime
  FROM trips_2018  AS t
  JOIN top_station AS s
  ON t.start_station_id = s.start_station_id
),
-- day‑of‑week with the greatest number of trips
top_day AS (
  SELECT
    EXTRACT(DAYOFWEEK FROM starttime) AS numeric_day_of_week,
    COUNT(*) AS trips
  FROM station_trips
  GROUP BY numeric_day_of_week
  ORDER BY trips DESC, numeric_day_of_week
  LIMIT 1
),
-- hour of day with the greatest number of trips
top_hour AS (
  SELECT
    EXTRACT(HOUR FROM starttime) AS hour_of_day,
    COUNT(*) AS trips
  FROM station_trips
  GROUP BY hour_of_day
  ORDER BY trips DESC, hour_of_day
  LIMIT 1
)
SELECT
  (SELECT numeric_day_of_week FROM top_day) AS numeric_day_of_week,
  (SELECT hour_of_day        FROM top_hour) AS hour_of_day;