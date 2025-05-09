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
top_station AS (
  SELECT
    start_station_id
  FROM
    trips_2018
  GROUP BY
    start_station_id
  ORDER BY
    COUNT(*) DESC
  LIMIT 1
),
station_trips AS (
  SELECT
    starttime
  FROM
    trips_2018 t
  JOIN
    top_station s
  ON
    t.start_station_id = s.start_station_id
),
day_counts AS (
  SELECT
    EXTRACT(DAYOFWEEK FROM starttime) AS day_of_week,   -- 1 = Sunday … 7 = Saturday
    COUNT(*) AS trip_cnt
  FROM
    station_trips
  GROUP BY
    day_of_week
),
hour_counts AS (
  SELECT
    EXTRACT(HOUR FROM starttime) AS hour_of_day,         -- 0‑23
    COUNT(*) AS trip_cnt
  FROM
    station_trips
  GROUP BY
    hour_of_day
),
max_day AS (
  SELECT
    day_of_week
  FROM
    day_counts
  ORDER BY
    trip_cnt DESC,           -- most trips
    day_of_week              -- tie‑breaker: lowest numeric day
  LIMIT 1
),
max_hour AS (
  SELECT
    hour_of_day
  FROM
    hour_counts
  ORDER BY
    trip_cnt DESC,           -- most trips
    hour_of_day              -- tie‑breaker: earliest hour
  LIMIT 1
)
SELECT
  (SELECT day_of_week FROM max_day)  AS numeric_day_of_week,
  (SELECT hour_of_day FROM max_hour) AS hour_of_day_with_most_trips;