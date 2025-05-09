WITH trips_2018 AS (
  SELECT
    start_station_id,
    starttime
  FROM `bigquery-public-data.new_york_citibike.citibike_trips`
  WHERE EXTRACT(YEAR FROM starttime) = 2018
),

-- Find the station with the most trip starts in 2018
top_station AS (
  SELECT
    start_station_id
  FROM trips_2018
  GROUP BY start_station_id
  ORDER BY COUNT(*) DESC
  LIMIT 1
),

-- Within that station, find the busiest day‑of‑week / hour combination
peak_day_hour AS (
  SELECT
    EXTRACT(DAYOFWEEK FROM starttime) AS numeric_day_of_week,   -- 1 = Sunday … 7 = Saturday
    EXTRACT(HOUR FROM starttime)     AS hour_of_day,            -- 0‑23
    COUNT(*)                         AS trip_count
  FROM trips_2018
  WHERE start_station_id = (SELECT start_station_id FROM top_station)
  GROUP BY numeric_day_of_week, hour_of_day
)

SELECT
  numeric_day_of_week,
  hour_of_day
FROM peak_day_hour
ORDER BY trip_count DESC, numeric_day_of_week, hour_of_day
LIMIT 1;