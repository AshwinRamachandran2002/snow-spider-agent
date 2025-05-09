-- Numeric day-of-week and hour with the most trips from the single busiest
-- start-station in 2018
WITH top_station AS (
  SELECT start_station_id
  FROM `bigquery-public-data.new_york_citibike.citibike_trips`
  WHERE EXTRACT(YEAR FROM starttime) = 2018
  GROUP BY start_station_id
  ORDER BY COUNT(*) DESC
  LIMIT 1
)
SELECT
  EXTRACT(DAYOFWEEK FROM t.starttime) AS day_of_week,   -- 1 = Sunday … 7 = Saturday
  EXTRACT(HOUR      FROM t.starttime) AS hour_of_day,    -- 0-23
  COUNT(*) AS trips
FROM `bigquery-public-data.new_york_citibike.citibike_trips` AS t
JOIN top_station s
  ON t.start_station_id = s.start_station_id
WHERE EXTRACT(YEAR FROM t.starttime) = 2018
GROUP BY day_of_week, hour_of_day
ORDER BY trips DESC
LIMIT 1;