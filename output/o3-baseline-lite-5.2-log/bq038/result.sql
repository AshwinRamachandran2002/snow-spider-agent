-- Top 10 Citi Bike stations by share of “group rides”
WITH same_station_trips AS (
  -- trips that start and end at the same station
  SELECT
    start_station_id   AS station_id,
    COALESCE(start_station_name, end_station_name) AS station_name,
    starttime
  FROM `bigquery-public-data.new_york.citibike_trips`
  WHERE start_station_id IS NOT NULL
    AND start_station_id = end_station_id
),
bucketed AS (
  -- place each trip in a rolling 2‑minute bucket
  SELECT
    station_id,
    station_name,
    CAST(FLOOR(UNIX_SECONDS(starttime)/120) AS INT64) AS two_min_bucket,
    starttime
  FROM same_station_trips
),
buckets_with_groups AS (
  -- keep only buckets where 2 + riders departed within the same 2‑minute window
  SELECT
    station_id,
    station_name,
    two_min_bucket
  FROM bucketed
  GROUP BY station_id, station_name, two_min_bucket
  HAVING COUNT(*) > 1
),
group_trips AS (
  -- all trips that belong to those “group” buckets
  SELECT b.station_id,
         b.station_name
  FROM bucketed            AS b
  JOIN buckets_with_groups AS g
  USING (station_id, two_min_bucket)
),
numerator AS (
  -- number of group‑ride trips per station
  SELECT
    station_id,
    station_name,
    COUNT(*) AS group_trip_cnt
  FROM group_trips
  GROUP BY station_id, station_name
),
denominator AS (
  -- total trips that END at each station
  SELECT
    end_station_id AS station_id,
    MAX(end_station_name) AS station_name,
    COUNT(*) AS total_trip_cnt
  FROM `bigquery-public-data.new_york.citibike_trips`
  WHERE end_station_id IS NOT NULL
  GROUP BY end_station_id
),
proportions AS (
  -- combine numerator & denominator
  SELECT
    d.station_id,
    d.station_name,
    IFNULL(n.group_trip_cnt, 0) AS group_trip_cnt,
    d.total_trip_cnt,
    SAFE_DIVIDE(IFNULL(n.group_trip_cnt, 0), d.total_trip_cnt) AS group_share
  FROM denominator d
  LEFT JOIN numerator n USING (station_id)
)
SELECT
  station_id,
  station_name,
  group_trip_cnt,
  total_trip_cnt,
  ROUND(group_share, 4) AS group_share
FROM proportions
WHERE total_trip_cnt > 0
ORDER BY group_share DESC, station_id
LIMIT 10;