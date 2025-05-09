-- Top 10 Citi Bike stations by proportion of “group rides”
-- (loop trips that start & end at the same station and where ≥2 such
-- trips begin within the same 2‑minute window)

WITH all_trips AS (
  SELECT
    CAST(start_station_id AS STRING)  AS start_id,
    CAST(end_station_id   AS STRING)  AS end_id,
    starttime
  FROM `bigquery-public-data.new_york.citibike_trips`
  WHERE end_station_id IS NOT NULL
),

-- loop trips (start‑station = end‑station)
loop_trips AS (
  SELECT
    end_id        AS station_id,
    starttime,
    -- bucket every 2 minutes
    FLOOR(UNIX_SECONDS(starttime) / 120) AS window_id
  FROM all_trips
  WHERE start_id = end_id
),

-- 2‑minute windows that actually contain a “group” (≥2 trips)
group_windows AS (
  SELECT station_id, window_id
  FROM loop_trips
  GROUP BY station_id, window_id
  HAVING COUNT(*) > 1
),

-- trips that belong to those “group” windows
group_trips AS (
  SELECT lt.station_id
  FROM loop_trips lt
  JOIN group_windows gw
  ON  lt.station_id = gw.station_id
  AND lt.window_id  = gw.window_id
),

-- count of group trips per station
group_counts AS (
  SELECT station_id, COUNT(*) AS group_trip_count
  FROM group_trips
  GROUP BY station_id
),

-- total trips ending at each station (denominator)
total_counts AS (
  SELECT end_id AS station_id, COUNT(*) AS total_trip_count
  FROM all_trips
  GROUP BY station_id
),

-- combine, compute proportion
proportions AS (
  SELECT
    tc.station_id,
    IFNULL(gc.group_trip_count,0) AS group_trip_count,
    tc.total_trip_count,
    SAFE_DIVIDE(IFNULL(gc.group_trip_count,0), tc.total_trip_count) AS proportion
  FROM total_counts tc
  LEFT JOIN group_counts gc
  USING (station_id)
)

SELECT
  s.name                               AS station_name,
  p.station_id,
  p.group_trip_count,
  p.total_trip_count,
  ROUND(p.proportion,4)                AS group_trip_proportion
FROM proportions p
LEFT JOIN `bigquery-public-data.new_york.citibike_stations` s
ON p.station_id = s.station_id
ORDER BY group_trip_proportion DESC, p.station_id
LIMIT 10;