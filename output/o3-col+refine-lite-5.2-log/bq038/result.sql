-- Top 10 Citi Bike stations by highest proportion of “group‑ride” trips
WITH loops AS (   -- trips that start & end at the same station
  SELECT
    start_station_id,
    FLOOR(UNIX_SECONDS(starttime) / 120) AS bucket_id
  FROM `bigquery-public-data.new_york.citibike_trips`
  WHERE start_station_id = end_station_id
    AND start_station_id IS NOT NULL
),

group_buckets AS (   -- (station , 2‑minute window) pairs that have ≥ 2 such trips
  SELECT
    start_station_id,
    bucket_id
  FROM loops
  GROUP BY start_station_id, bucket_id
  HAVING COUNT(*) >= 2
),

group_trips AS (     -- count of trips that belong to those qualifying buckets
  SELECT
    l.start_station_id AS station_id,
    COUNT(*)           AS group_trip_count
  FROM loops AS l
  JOIN group_buckets AS g
    ON l.start_station_id = g.start_station_id
   AND l.bucket_id        = g.bucket_id
  GROUP BY station_id
),

total_end AS (       -- total trips ending at each station (denominator)
  SELECT
    end_station_id AS station_id,
    COUNT(*)       AS total_end_trips
  FROM `bigquery-public-data.new_york.citibike_trips`
  WHERE end_station_id IS NOT NULL
  GROUP BY station_id
),

ratios AS (          -- compute proportion of group trips
  SELECT
    t.station_id,
    g.group_trip_count,
    t.total_end_trips,
    g.group_trip_count / t.total_end_trips AS group_trip_ratio
  FROM total_end AS t
  JOIN group_trips AS g
    ON t.station_id = g.station_id          -- inner join keeps only stations with ≥1 group trip
)

SELECT
  r.station_id,
  s.name                       AS station_name,
  r.group_trip_count,
  r.total_end_trips,
  ROUND(r.group_trip_ratio, 4) AS group_trip_ratio
FROM ratios AS r
LEFT JOIN `bigquery-public-data.new_york.citibike_stations` AS s
  ON SAFE_CAST(s.station_id AS INT64) = r.station_id
ORDER BY r.group_trip_ratio DESC, r.station_id
LIMIT 10;