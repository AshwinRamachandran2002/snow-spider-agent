-- Busiest numeric day-of-week and hour-of-day for the station
-- with the most trip starts in 2018
WITH top_station AS (
  SELECT start_station_id
  FROM `bigquery-public-data.new_york_citibike.citibike_trips`
  WHERE EXTRACT(YEAR FROM starttime)=2018
  GROUP BY start_station_id
  ORDER BY COUNT(*) DESC
  LIMIT 1
),
filtered_trips AS (
  SELECT starttime
  FROM `bigquery-public-data.new_york_citibike.citibike_trips` t
  JOIN top_station s
    ON t.start_station_id = s.start_station_id
  WHERE EXTRACT(YEAR FROM t.starttime)=2018
),
busiest_dow AS (
  SELECT EXTRACT(DAYOFWEEK FROM starttime) AS dow_num,
         COUNT(*) AS trips
  FROM filtered_trips
  GROUP BY dow_num
  ORDER BY trips DESC
  LIMIT 1
),
busiest_hour AS (
  SELECT EXTRACT(HOUR FROM starttime) AS hour_of_day,
         COUNT(*) AS trips
  FROM filtered_trips
  GROUP BY hour_of_day
  ORDER BY trips DESC
  LIMIT 1
)
SELECT
  (SELECT dow_num   FROM busiest_dow)  AS busiest_numeric_day_of_week,
  (SELECT hour_of_day FROM busiest_hour) AS busiest_hour_of_day;