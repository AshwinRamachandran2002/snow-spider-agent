-- top 10 Citi Bike stations ranked by the share of trips that are “group rides”
WITH round_trips AS (           -- trips that start AND end at the same station
  SELECT
    start_station_id,
    starttime
  FROM `bigquery-public-data.new_york.citibike_trips`
  WHERE start_station_id IS NOT NULL
    AND end_station_id   IS NOT NULL
    AND start_station_id = end_station_id
),
bucketed AS (                  -- place every round‑trip into a 2‑minute bucket
  SELECT
    start_station_id                           AS station_id,
    FLOOR(UNIX_SECONDS(starttime)/120)         AS bucket_2min,
    COUNT(*)                                   AS trips_in_bucket
  FROM round_trips
  GROUP BY station_id, bucket_2min
  HAVING trips_in_bucket >= 2                  -- bucket represents a group ride
),
group_ride_trips AS (           -- every trip that falls in a qualifying bucket
  SELECT
    rt.start_station_id AS station_id
  FROM round_trips        AS rt
  JOIN bucketed           AS b
    ON  b.station_id   = rt.start_station_id
    AND b.bucket_2min  = FLOOR(UNIX_SECONDS(rt.starttime)/120)
),
group_ride_counts AS (
  SELECT
    station_id,
    COUNT(*) AS group_trip_cnt
  FROM group_ride_trips
  GROUP BY station_id
),
total_end_counts AS (          -- denominator: ALL trips that end at the station
  SELECT
    end_station_id AS station_id,
    COUNT(*)       AS total_end_cnt
  FROM `bigquery-public-data.new_york.citibike_trips`
  WHERE end_station_id IS NOT NULL
  GROUP BY station_id
),
proportions AS (               -- compute share of group rides per station
  SELECT
    te.station_id,
    gr.group_trip_cnt,
    te.total_end_cnt,
    SAFE_DIVIDE(gr.group_trip_cnt, te.total_end_cnt) AS proportion
  FROM total_end_counts te
  JOIN group_ride_counts gr
    ON gr.station_id = te.station_id
)
SELECT
  CAST(p.station_id AS STRING)                       AS station_id,
  ANY_VALUE(s.name)                                  AS station_name,
  p.group_trip_cnt,
  p.total_end_cnt,
  ROUND(p.proportion, 4)                             AS group_trip_proportion
FROM proportions p
LEFT JOIN `bigquery-public-data.new_york.citibike_stations` s
  ON s.station_id = CAST(p.station_id AS STRING)
GROUP BY station_id, group_trip_cnt, total_end_cnt, group_trip_proportion
ORDER BY group_trip_proportion DESC, station_id
LIMIT 10;