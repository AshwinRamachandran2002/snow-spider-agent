WITH loops AS (
  -- trips that start AND end at the same station
  SELECT
    start_station_id,
    DIV(UNIX_SECONDS(starttime),120) AS bucket_id          -- 2-minute window
  FROM `bigquery-public-data.new_york.citibike_trips`
  WHERE start_station_id = end_station_id
),
group_buckets AS (
  -- (station, bucket) pairs that have ≥ 2 such trips → “group ride” windows
  SELECT
    start_station_id AS station_id,
    bucket_id
  FROM loops
  GROUP BY station_id, bucket_id
  HAVING COUNT(*) >= 2
),
group_trip_counts AS (
  -- number of individual trips that belong to a group ride at each station
  SELECT
    l.start_station_id AS station_id,
    COUNT(*) AS group_trip_count
  FROM loops l
  JOIN group_buckets g
    ON l.start_station_id = g.station_id
   AND l.bucket_id        = g.bucket_id
  GROUP BY station_id
),
total_trips_end AS (
  -- total number of trips that END at each station (denominator)
  SELECT
    end_station_id AS station_id,
    COUNT(*)       AS total_trips_end
  FROM `bigquery-public-data.new_york.citibike_trips`
  GROUP BY station_id
),
proportions AS (
  -- combine counts and compute proportion of group rides
  SELECT
    t.station_id,
    COALESCE(g.group_trip_count,0) AS group_trip_count,
    t.total_trips_end,
    SAFE_DIVIDE(COALESCE(g.group_trip_count,0), t.total_trips_end) AS proportion
  FROM total_trips_end t
  LEFT JOIN group_trip_counts g USING (station_id)
)
SELECT
  p.station_id,
  s.name AS station_name,
  p.group_trip_count,
  p.total_trips_end,
  ROUND(p.proportion,4) AS proportion
FROM proportions p
LEFT JOIN `bigquery-public-data.new_york.citibike_stations` s
       ON s.station_id = CAST(p.station_id AS STRING)   -- trips IDs are INT64, stations table uses STRING
ORDER BY proportion DESC
LIMIT 10;