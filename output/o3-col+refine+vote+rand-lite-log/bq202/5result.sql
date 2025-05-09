-- Numeric day-of-week and hour with the most 2018 trips at the year’s top origin station
WITH top_station AS (
  SELECT
    start_station_id AS id
  FROM `bigquery-public-data.new_york_citibike.citibike_trips`
  WHERE EXTRACT(YEAR FROM starttime) = 2018
  GROUP BY start_station_id
  ORDER BY COUNT(*) DESC
  LIMIT 1
),
dow_hour_counts AS (
  SELECT
    EXTRACT(DAYOFWEEK FROM starttime) AS dow_num,   -- 1 = Sun … 7 = Sat
    EXTRACT(HOUR      FROM starttime) AS hour_of_day,
    COUNT(*)                              AS trips
  FROM `bigquery-public-data.new_york_citibike.citibike_trips`, top_station
  WHERE EXTRACT(YEAR FROM starttime) = 2018
    AND start_station_id = top_station.id
  GROUP BY dow_num, hour_of_day
)
SELECT
  dow_num,
  hour_of_day
FROM dow_hour_counts
ORDER BY trips DESC
LIMIT 1;