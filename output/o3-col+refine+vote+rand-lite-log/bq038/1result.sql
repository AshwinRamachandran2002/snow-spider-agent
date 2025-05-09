-- Top-10 Citi Bike stations ranked by the share of “group rides”
WITH
-- 1.  Round-trips: rides that start and end at the same station
round_trips AS (
  SELECT
    start_station_id         AS station_id,
    starttime                AS start_ts
  FROM `bigquery-public-data.new_york.citibike_trips`
  WHERE start_station_id IS NOT NULL
    AND start_station_id = end_station_id
),

-- 2.  Place those round-trips into 2-minute buckets
buckets AS (
  SELECT
    station_id,
    TIMESTAMP_SECONDS( 120 * DIV( UNIX_SECONDS(start_ts), 120) ) AS bucket
  FROM round_trips
),

-- 3.  Keep only buckets that contain >1 trips  → a “group-ride” moment
group_buckets AS (
  SELECT
    station_id,
    bucket
  FROM buckets
  GROUP BY station_id, bucket
  HAVING COUNT(*) > 1
),

-- 4.  Count how many individual trips are part of those qualifying buckets
group_ct AS (
  SELECT
    r.station_id,
    COUNT(*) AS group_trips
  FROM round_trips r
  JOIN group_buckets g
    ON  g.station_id = r.station_id
    AND g.bucket     = TIMESTAMP_SECONDS( 120 * DIV( UNIX_SECONDS(r.start_ts), 120) )
  GROUP BY r.station_id
),

-- 5.  Total trips that END at each station (denominator for the proportion)
total_ct AS (
  SELECT
    end_station_id AS station_id,
    COUNT(*)       AS total_trips_end_here
  FROM `bigquery-public-data.new_york.citibike_trips`
  WHERE end_station_id IS NOT NULL
  GROUP BY end_station_id
)

-- 6.  Final list with proportions and station names
SELECT
  s.name                                           AS station_name,
  gc.group_trips,
  tc.total_trips_end_here,
  SAFE_DIVIDE(gc.group_trips, tc.total_trips_end_here) AS proportion_group_rides
FROM group_ct gc
JOIN total_ct tc        USING (station_id)
JOIN `bigquery-public-data.new_york.citibike_stations` s
     ON s.station_id = CAST(gc.station_id AS STRING)
ORDER BY proportion_group_rides DESC
LIMIT 10;