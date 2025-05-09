-- Day-of-week and hour with the most 2018 trips from the busiest start-station
WITH top_station AS (
  SELECT start_station_id AS id
  FROM `bigquery-public-data.new_york_citibike.citibike_trips`
  WHERE EXTRACT(YEAR FROM starttime) = 2018
  GROUP BY id
  ORDER BY COUNT(*) DESC
  LIMIT 1
),
dow_hr_counts AS (
  SELECT
    EXTRACT(DAYOFWEEK FROM t.starttime) AS dow_num,
    EXTRACT(HOUR      FROM t.starttime) AS hr,
    COUNT(*) AS trips
  FROM `bigquery-public-data.new_york_citibike.citibike_trips` AS t
  JOIN top_station AS s ON t.start_station_id = s.id
  WHERE EXTRACT(YEAR FROM t.starttime) = 2018
  GROUP BY dow_num, hr
)
SELECT
  dow_num,   -- numeric day of week (1 = Sun … 7 = Sat)
  hr         -- hour of day (0–23)
FROM dow_hr_counts
ORDER BY trips DESC
LIMIT 1;