-- numeric day-of-week (1 = Sunday … 7 = Saturday) and hour-of-day (0-23)
-- that registered the most trip starts at 2018’s busiest Citi Bike station
WITH top_station AS (                -- station with the most 2018 trip starts
  SELECT start_station_id
  FROM `bigquery-public-data.new_york_citibike.citibike_trips`
  WHERE EXTRACT(YEAR FROM starttime) = 2018
  GROUP BY start_station_id
  ORDER BY COUNT(*) DESC
  LIMIT 1
)
SELECT
  EXTRACT(DAYOFWEEK FROM starttime) AS numeric_day_of_week,
  EXTRACT(HOUR      FROM starttime) AS hour_of_day,
  COUNT(*) AS trips                   -- optional: shows how many starts occurred
FROM `bigquery-public-data.new_york_citibike.citibike_trips`
WHERE EXTRACT(YEAR FROM starttime) = 2018
  AND start_station_id = (SELECT start_station_id FROM top_station)
GROUP BY numeric_day_of_week, hour_of_day
ORDER BY trips DESC
LIMIT 1;