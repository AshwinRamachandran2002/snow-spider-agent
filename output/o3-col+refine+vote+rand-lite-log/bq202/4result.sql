-- Identify the (day-of-week, hour) combination with the most trips
-- for 2018’s single busiest origin station.
WITH top_station AS (
  SELECT
    start_station_id
  FROM `bigquery-public-data.new_york_citibike.citibike_trips`
  WHERE EXTRACT(YEAR FROM starttime) = 2018
  GROUP BY start_station_id
  ORDER BY COUNT(*) DESC
  LIMIT 1
)
SELECT
  EXTRACT(DAYOFWEEK FROM t.starttime) AS busiest_dow,   -- 1 = Sunday … 7 = Saturday
  EXTRACT(HOUR      FROM t.starttime) AS busiest_hour,  -- 0-23
  COUNT(*)                          AS trips
FROM `bigquery-public-data.new_york_citibike.citibike_trips` AS t
JOIN top_station AS s
  ON t.start_station_id = s.start_station_id
WHERE EXTRACT(YEAR FROM t.starttime) = 2018
GROUP BY busiest_dow, busiest_hour
ORDER BY trips DESC
LIMIT 1;