-- Day-of-week (1=Sun … 7=Sat) and hour (0-23) with the most trip starts
-- for the single busiest Citibike start-station in 2018
WITH trips_2018 AS (
  SELECT start_station_id, starttime
  FROM   `bigquery-public-data.new_york_citibike.citibike_trips`
  WHERE  EXTRACT(YEAR FROM starttime) = 2018
),
top_station AS (
  SELECT start_station_id
  FROM   trips_2018
  GROUP  BY start_station_id
  ORDER  BY COUNT(*) DESC
  LIMIT  1
),
dow_hr_counts AS (
  SELECT
    EXTRACT(DAYOFWEEK FROM t.starttime) AS dow,
    EXTRACT(HOUR      FROM t.starttime) AS hr,
    COUNT(*)                            AS trips
  FROM   trips_2018 AS t
  JOIN   top_station USING (start_station_id)
  GROUP  BY dow, hr
)
SELECT
  dow  AS busiest_day_of_week,
  hr   AS busiest_hour,
  trips
FROM   dow_hr_counts
ORDER  BY trips DESC
LIMIT  1;