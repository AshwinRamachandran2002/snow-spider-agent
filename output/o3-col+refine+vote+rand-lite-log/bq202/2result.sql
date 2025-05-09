WITH trips_2018 AS (          -- all Citi Bike trips that began in 2018
  SELECT
    start_station_id,
    starttime
  FROM `bigquery-public-data.new_york_citibike.citibike_trips`
  WHERE EXTRACT(YEAR FROM starttime) = 2018
),

busiest_station AS (          -- station with the most 2018 departures
  SELECT
    start_station_id
  FROM trips_2018
  GROUP BY start_station_id
  ORDER BY COUNT(*) DESC
  LIMIT 1
),

busiest_trips AS (            -- 2018 trips that started at that station
  SELECT
    t.starttime
  FROM trips_2018 t
  JOIN busiest_station b
    ON t.start_station_id = b.start_station_id
),

top_day AS (                  -- most common numeric day-of-week (1-Sun … 7-Sat)
  SELECT
    EXTRACT(DAYOFWEEK FROM starttime) AS numeric_day_of_week
  FROM busiest_trips
  GROUP BY numeric_day_of_week
  ORDER BY COUNT(*) DESC
  LIMIT 1
),

top_hour AS (                 -- most common hour of day (0-23)
  SELECT
    EXTRACT(HOUR FROM starttime) AS hour_of_day
  FROM busiest_trips
  GROUP BY hour_of_day
  ORDER BY COUNT(*) DESC
  LIMIT 1
)

SELECT
  (SELECT numeric_day_of_week FROM top_day) AS numeric_day_of_week,
  (SELECT hour_of_day        FROM top_hour) AS hour_of_day;