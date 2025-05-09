WITH top_station AS (
  -- 1️⃣  Find the 2018 start‑station with the most trips
  SELECT
    start_station_id
  FROM `bigquery-public-data.new_york_citibike.citibike_trips`
  WHERE EXTRACT(YEAR FROM starttime) = 2018
  GROUP BY start_station_id
  ORDER BY COUNT(*) DESC
  LIMIT 1
),
peak_period AS (
  -- 2️⃣  Within that station, count trips for every (day‑of‑week, hour) pair
  SELECT
    EXTRACT(DAYOFWEEK FROM t.starttime) AS day_of_week,   -- Sunday = 1
    EXTRACT(HOUR      FROM t.starttime) AS hour_of_day,   -- 0‑23 (NYC local)
    COUNT(*)                            AS trips
  FROM `bigquery-public-data.new_york_citibike.citibike_trips` AS t
  JOIN top_station AS s
    ON t.start_station_id = s.start_station_id
  WHERE EXTRACT(YEAR FROM t.starttime) = 2018
  GROUP BY day_of_week, hour_of_day
)
-- 3️⃣  Return the single (day, hour) combination with the most starts
SELECT
  day_of_week,
  hour_of_day,
  trips
FROM peak_period
ORDER BY trips DESC
LIMIT 1;