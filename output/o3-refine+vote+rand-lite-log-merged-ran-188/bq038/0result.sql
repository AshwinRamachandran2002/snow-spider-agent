-- Top 10 Citi Bike stations with the highest share of “group rides”
WITH loop_trips AS (
  -- 1. Trips that start and finish at the same station
  SELECT
    start_station_id          AS station_id,
    start_station_name        AS station_name,
    starttime
  FROM `bigquery-public-data.new_york.citibike_trips`
  WHERE start_station_id IS NOT NULL
    AND start_station_id = end_station_id
),
bucketed AS (
  -- 2. Put every loop‑trip into a rolling 2‑minute bucket
  SELECT
    station_id,
    station_name,
    starttime,
    -- 120‑second buckets (UNIX time is in seconds)
    FLOOR(UNIX_SECONDS(starttime) / 120) AS bucket_id
  FROM loop_trips
),
bucket_counts AS (
  -- 3. Keep only buckets that contain at least 2 trips
  SELECT
    station_id,
    bucket_id,
    COUNT(*) AS trips_in_bucket
  FROM bucketed
  GROUP BY station_id, bucket_id
  HAVING trips_in_bucket >= 2
),
group_trips AS (
  -- 4. Trips that are part of a “group ride”
  SELECT
    b.station_id,
    b.station_name
  FROM bucketed b
  JOIN bucket_counts bc
    ON b.station_id = bc.station_id
   AND b.bucket_id  = bc.bucket_id
),
group_counts AS (
  -- 5. Number of group‑ride trips per station
  SELECT
    station_id,
    ANY_VALUE(station_name) AS station_name,
    COUNT(*)               AS group_trip_cnt
  FROM group_trips
  GROUP BY station_id
),
end_counts AS (
  -- 6. All trips that END at each station (denominator)
  SELECT
    end_station_id          AS station_id,
    ANY_VALUE(end_station_name) AS station_name,
    COUNT(*)                AS total_end_trips
  FROM `bigquery-public-data.new_york.citibike_trips`
  WHERE end_station_id IS NOT NULL
  GROUP BY station_id
)
-- 7. Combine, compute proportion, and return top 10
SELECT
  e.station_id,
  e.station_name,
  g.group_trip_cnt,
  e.total_end_trips,
  SAFE_DIVIDE(g.group_trip_cnt, e.total_end_trips) AS group_trip_proportion
FROM end_counts e
JOIN group_counts g
  ON e.station_id = g.station_id
ORDER BY
  group_trip_proportion DESC,
  e.station_id
LIMIT 10;