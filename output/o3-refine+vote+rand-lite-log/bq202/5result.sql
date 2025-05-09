WITH trips_2018 AS (
  SELECT *
  FROM `bigquery-public-data.new_york_citibike.citibike_trips`
  WHERE EXTRACT(YEAR FROM starttime) = 2018
),
top_station AS (
  SELECT start_station_id
  FROM trips_2018
  GROUP BY start_station_id
  ORDER BY COUNT(*) DESC
  LIMIT 1
),
peak_day AS (
  SELECT
    EXTRACT(DAYOFWEEK FROM starttime) AS numeric_day_of_week,
    COUNT(*) AS trip_cnt
  FROM trips_2018
  WHERE start_station_id = (SELECT start_station_id FROM top_station)
  GROUP BY numeric_day_of_week
  ORDER BY trip_cnt DESC
  LIMIT 1
),
peak_hour AS (
  SELECT
    EXTRACT(HOUR FROM starttime) AS hour_of_day,
    COUNT(*) AS trip_cnt
  FROM trips_2018
  WHERE start_station_id = (SELECT start_station_id FROM top_station)
  GROUP BY hour_of_day
  ORDER BY trip_cnt DESC
  LIMIT 1
)
SELECT
  (SELECT numeric_day_of_week FROM peak_day) AS numeric_day_of_week,
  (SELECT hour_of_day FROM peak_hour)        AS hour_of_day;