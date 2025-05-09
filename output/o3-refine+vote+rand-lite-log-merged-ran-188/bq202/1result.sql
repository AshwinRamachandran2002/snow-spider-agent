WITH trips_2018 AS (
  SELECT
    start_station_id,
    starttime
  FROM
    `bigquery-public-data.new_york_citibike.citibike_trips`
  WHERE
    starttime >= '2018-01-01'
    AND starttime < '2019-01-01'
    AND start_station_id IS NOT NULL
),

-- Identify the station with the most trip starts in 2018
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

-- Trips that started at that station
station_trips AS (
  SELECT
    EXTRACT(DAYOFWEEK FROM starttime) AS day_of_week,   -- 1 = Sunday … 7 = Saturday
    EXTRACT(HOUR      FROM starttime) AS hour_of_day
  FROM
    trips_2018
  WHERE
    start_station_id = (SELECT start_station_id FROM top_station)
)

-- Find the (day_of_week, hour_of_day) pair with the most trips
SELECT
  day_of_week,
  hour_of_day
FROM
  station_trips
GROUP BY
  day_of_week,
  hour_of_day
ORDER BY
  COUNT(*) DESC,
  day_of_week,
  hour_of_day
LIMIT 1;