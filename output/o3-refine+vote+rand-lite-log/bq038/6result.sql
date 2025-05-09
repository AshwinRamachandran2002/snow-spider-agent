WITH loop_trips AS (        -- trips that start and end at the same station
  SELECT
    start_station_id AS station_id,
    CAST(UNIX_SECONDS(starttime) / 120 AS INT64) AS time_bucket   -- 2‑minute buckets
  FROM `bigquery-public-data.new_york.citibike_trips`
  WHERE start_station_id IS NOT NULL
    AND end_station_id   IS NOT NULL
    AND start_station_id = end_station_id
),

buckets_with_groups AS (    -- buckets that actually contain a “group” (≥2 trips)
  SELECT
    station_id,
    time_bucket,
    COUNT(*) AS trips_in_bucket
  FROM loop_trips
  GROUP BY station_id, time_bucket
  HAVING trips_in_bucket >= 2
),

group_ride_trips AS (       -- every individual trip that belongs to a “group” bucket
  SELECT lt.station_id
  FROM   loop_trips lt
  JOIN   buckets_with_groups bg
  USING  (station_id, time_bucket)
),

group_ride_counts AS (      -- number of group‑ride trips per station
  SELECT
    station_id,
    COUNT(*) AS group_trip_count
  FROM group_ride_trips
  GROUP BY station_id
),

ending_trip_counts AS (     -- total trips ending at each station (denominator)
  SELECT
    end_station_id AS station_id,
    COUNT(*)       AS total_trips_end
  FROM `bigquery-public-data.new_york.citibike_trips`
  WHERE end_station_id IS NOT NULL
  GROUP BY end_station_id
),

proportions AS (            -- compute proportion of group rides
  SELECT
    e.station_id,
    COALESCE(g.group_trip_count, 0) AS group_trip_count,
    e.total_trips_end,
    SAFE_DIVIDE(COALESCE(g.group_trip_count, 0), e.total_trips_end) AS group_proportion
  FROM ending_trip_counts e
  LEFT JOIN group_ride_counts g USING (station_id)
),

station_names AS (          -- keep station_id as STRING to avoid cast errors
  SELECT DISTINCT
    station_id,            -- STRING
    name
  FROM `bigquery-public-data.new_york.citibike_stations`
)

SELECT
  p.station_id,                                   -- INT64
  sn.name                     AS station_name,
  p.group_trip_count,
  p.total_trips_end,
  ROUND(p.group_proportion, 4) AS group_proportion
FROM proportions p
LEFT JOIN station_names sn
       ON sn.station_id = CAST(p.station_id AS STRING)
ORDER BY group_proportion DESC, p.group_trip_count DESC
LIMIT 10;