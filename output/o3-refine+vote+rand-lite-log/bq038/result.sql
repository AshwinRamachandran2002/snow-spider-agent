-- Top‑10 Citi Bike stations by share of “group rides”
-- (round trips where ≥2 bikes left in the same 2‑minute window)

WITH base AS (
  SELECT
    start_station_id,
    end_station_id,
    starttime
  FROM `bigquery-public-data.new_york.citibike_trips`
  WHERE start_station_id IS NOT NULL
    AND end_station_id   IS NOT NULL
),

-- round‑trips: start & end at the same station
round_trips AS (
  SELECT
    *,
    -- bucket departure time into 2‑minute intervals
    TIMESTAMP_SECONDS(120 * DIV(UNIX_SECONDS(starttime),120)) AS bucket_2min
  FROM base
  WHERE start_station_id = end_station_id
),

-- 2‑minute buckets that involve a group (≥2 trips)
group_buckets AS (
  SELECT
    start_station_id          AS station_id,
    bucket_2min,
    COUNT(*)                  AS trips_in_bucket
  FROM round_trips
  GROUP BY station_id, bucket_2min
  HAVING trips_in_bucket >= 2
),

-- every trip that belongs to one of those “group” buckets
group_rides AS (
  SELECT rt.*
  FROM round_trips  AS rt
  JOIN group_buckets AS gb
    ON rt.start_station_id = gb.station_id
   AND rt.bucket_2min     = gb.bucket_2min
),

-- total trips that END at each station (denominator)
totals AS (
  SELECT
    end_station_id AS station_id,
    COUNT(*)       AS total_trips_end
  FROM base
  GROUP BY station_id
),

-- number of group‑ride trips that END at each station (numerator)
group_counts AS (
  SELECT
    end_station_id AS station_id,
    COUNT(*)       AS group_trips
  FROM group_rides
  GROUP BY station_id
),

-- proportion calculation
proportions AS (
  SELECT
    t.station_id,
    IFNULL(g.group_trips,0)          AS group_trips,
    t.total_trips_end,
    SAFE_DIVIDE(IFNULL(g.group_trips,0), t.total_trips_end) AS proportion
  FROM totals t
  LEFT JOIN group_counts g
    USING (station_id)
)

SELECT
  station_id,
  proportion,
  group_trips,
  total_trips_end
FROM proportions
ORDER BY proportion DESC, station_id
LIMIT 10;