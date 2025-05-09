-- Numeric day‑of‑week (1=Sunday … 7=Saturday) and hour (0‑23) 
-- with the most trips for the busiest 2018 origin station
WITH trips_2018 AS (
  SELECT
    start_station_id,
    starttime
  FROM `bigquery-public-data.new_york_citibike.citibike_trips`
  WHERE EXTRACT(YEAR FROM starttime) = 2018
    AND start_station_id IS NOT NULL
),

-- find the station with the most trip starts in 2018
top_station AS (
  SELECT start_station_id
  FROM trips_2018
  GROUP BY start_station_id
  ORDER BY COUNT(*) DESC
  LIMIT 1
),

-- trips that started at that station
top_station_trips AS (
  SELECT starttime
  FROM trips_2018
  WHERE start_station_id = (SELECT start_station_id FROM top_station)
),

-- count by day‑of‑week and hour
dow_hour_counts AS (
  SELECT
    EXTRACT(DAYOFWEEK FROM starttime) AS day_of_week,
    EXTRACT(HOUR FROM starttime)      AS hour_of_day,
    COUNT(*)                          AS trip_cnt
  FROM top_station_trips
  GROUP BY day_of_week, hour_of_day
)

SELECT
  day_of_week,
  hour_of_day
FROM dow_hour_counts
ORDER BY trip_cnt DESC, day_of_week, hour_of_day
LIMIT 1;