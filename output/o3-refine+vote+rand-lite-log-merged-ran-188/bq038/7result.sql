WITH trips AS (      -- all trips that have a recorded end station
  SELECT
    GENERATE_UUID()                                  AS trip_id,
    CAST(start_station_id AS STRING)                 AS start_station_id,
    CAST(end_station_id   AS STRING)                 AS end_station_id,
    starttime,
    stoptime
  FROM `bigquery-public-data.new_york.citibike_trips`
  WHERE end_station_id IS NOT NULL
),

same_station AS (    -- trips that start and end at the same station
  SELECT
    trip_id,
    start_station_id                       AS station_id,
    DIV(UNIX_SECONDS(starttime),120)       AS start_bucket,   -- 2‑minute departure bucket (INT64)
    DIV(UNIX_SECONDS(stoptime) ,120)       AS end_bucket      -- 2‑minute arrival   bucket (INT64)
  FROM trips
  WHERE start_station_id = end_station_id
),

same_station_counts AS (   -- how many trips share each bucket
  SELECT
    trip_id,
    station_id,
    COUNT(*) OVER (PARTITION BY station_id, start_bucket) AS depart_cnt,
    COUNT(*) OVER (PARTITION BY station_id, end_bucket)   AS arrive_cnt
  FROM same_station
),

trip_flags AS (      -- flag a trip as “group” when criteria met
  SELECT
    t.trip_id,
    t.end_station_id                                                AS station_id,
    IF( COALESCE(c.depart_cnt,0) >= 2
        OR COALESCE(c.arrive_cnt,0) >= 2, 1, 0)                     AS is_group
  FROM trips t
  LEFT JOIN same_station_counts c
  ON t.trip_id = c.trip_id
),

station_stats AS (   -- station‑level metrics
  SELECT
    station_id,
    SUM(is_group)                                   AS group_trips,
    COUNT(*)                                        AS total_trips_ending,
    SAFE_DIVIDE(SUM(is_group), COUNT(*))            AS proportion
  FROM trip_flags
  GROUP BY station_id
),

station_names AS (   -- readable station names
  SELECT
    CAST(station_id AS STRING)                      AS station_id,
    ANY_VALUE(name)                                 AS station_name
  FROM `bigquery-public-data.new_york.citibike_stations`
  GROUP BY station_id
)

SELECT
  s.station_id,
  n.station_name,
  s.group_trips,
  s.total_trips_ending,
  ROUND(s.proportion,4)                             AS proportion
FROM station_stats s
LEFT JOIN station_names n
ON s.station_id = n.station_id
ORDER BY proportion DESC, s.station_id
LIMIT 10;