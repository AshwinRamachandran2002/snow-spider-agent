WITH busiest_station AS (
  SELECT start_station_id
  FROM `bigquery-public-data.new_york_citibike.citibike_trips`
  WHERE EXTRACT(YEAR FROM starttime) = 2018
    AND start_station_id IS NOT NULL
  GROUP BY start_station_id
  ORDER BY COUNT(*) DESC
  LIMIT 1
)
SELECT day_of_week, hour_of_day
FROM (
  SELECT
    EXTRACT(DAYOFWEEK FROM starttime) AS day_of_week,
    EXTRACT(HOUR FROM starttime) AS hour_of_day,
    COUNT(*) AS trip_count
  FROM `bigquery-public-data.new_york_citibike.citibike_trips`
  WHERE EXTRACT(YEAR FROM starttime) = 2018
    AND start_station_id = (SELECT start_station_id FROM busiest_station)
  GROUP BY day_of_week, hour_of_day
  ORDER BY trip_count DESC
  LIMIT 1
)