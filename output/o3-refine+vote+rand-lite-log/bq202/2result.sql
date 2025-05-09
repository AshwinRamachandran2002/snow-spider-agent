-- 1) find the start‑station with the most trips in 2018
-- 2) within that station’s 2018 trips, find the (day‑of‑week , hour) combo
--    that occurs most often
WITH trips_2018 AS (
  SELECT
    start_station_id,
    starttime
  FROM `bigquery-public-data.new_york_citibike.citibike_trips`
  WHERE EXTRACT(YEAR FROM starttime) = 2018
    AND start_station_id IS NOT NULL
),
top_station AS (                          -- step 1
  SELECT start_station_id
  FROM trips_2018
  GROUP BY start_station_id
  ORDER BY COUNT(*) DESC
  LIMIT 1
),
top_station_trips AS (                    -- all 2018 trips from that station
  SELECT t.starttime
  FROM trips_2018 t
  JOIN top_station s
  ON t.start_station_id = s.start_station_id
)
SELECT                                     -- step 2
  EXTRACT(DAYOFWEEK FROM starttime) AS numeric_day_of_week,   -- 1=Sun … 7=Sat
  EXTRACT(HOUR      FROM starttime) AS hour_of_day,           -- 0‑23
  COUNT(*)                               AS trips_ct
FROM top_station_trips
GROUP BY numeric_day_of_week, hour_of_day
ORDER BY trips_ct DESC
LIMIT 1;