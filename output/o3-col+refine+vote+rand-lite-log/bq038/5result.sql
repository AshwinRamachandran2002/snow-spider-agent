-- Top 10 Citi Bike stations by share of “group-ride” trips
WITH trips AS (
  SELECT
    start_station_id,
    end_station_id,
    starttime
  FROM `bigquery-public-data.new_york.citibike_trips`
  WHERE start_station_id IS NOT NULL
    AND end_station_id   IS NOT NULL
),

-- 1. Total # of trips that END at each station
total_end AS (
  SELECT
    end_station_id AS station_id,
    COUNT(*)       AS total_end_trips
  FROM trips
  GROUP BY station_id
),

-- 2. “Loop” trips (start & end at same station) + 2-minute bucket
loops AS (
  SELECT
    start_station_id                                AS station_id,
    starttime,
    TIMESTAMP_SECONDS(120 * DIV(UNIX_SECONDS(starttime),120)) AS win
  FROM trips
  WHERE start_station_id = end_station_id
),

-- 3. Flag each loop trip that belongs to a bucket with ≥ 2 trips
flagged AS (
  SELECT
    station_id,
    starttime,
    COUNT(*) OVER (PARTITION BY station_id, win) AS trips_in_win
  FROM loops
),

-- 4. Count trips that qualify as “group rides” at each station
group_trips AS (
  SELECT
    station_id,
    COUNT(*) AS group_trip_count
  FROM flagged
  WHERE trips_in_win >= 2      -- only keep group-ride trips
  GROUP BY station_id
),

-- 5. Combine counts, compute proportion, and rank
ratios AS (
  SELECT
    t.station_id,
    g.group_trip_count,
    t.total_end_trips,
    SAFE_DIVIDE(g.group_trip_count, t.total_end_trips) AS proportion
  FROM total_end   AS t
  JOIN group_trips AS g USING (station_id)
)

SELECT
  station_id,
  group_trip_count  AS group_rides,
  total_end_trips,
  proportion
FROM ratios
ORDER BY proportion DESC
LIMIT 10;