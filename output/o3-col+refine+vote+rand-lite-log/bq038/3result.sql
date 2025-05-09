-- Top-10 Citi Bike stations by share of “group rides”
--   • “Group ride” = trip that starts & ends at same station AND at least one other
--     trip ends at that same station within the same two-minute window.
--   • Proportion = (# group-ride trips) ÷ (all trips that end at the station)

WITH all_trips AS (
  SELECT
    start_station_id,
    end_station_id,
    stoptime
  FROM `bigquery-public-data.new_york.citibike_trips`
  WHERE end_station_id IS NOT NULL
),

-- Trips that start and end at the same station (“round trips”)
round_trips AS (
  SELECT
    end_station_id,
    -- floor stoptime to 2-minute buckets
    TIMESTAMP_SECONDS(DIV(UNIX_SECONDS(stoptime), 120) * 120) AS bucket_2min
  FROM all_trips
  WHERE start_station_id = end_station_id
),

-- Flag every round-trip that belongs to a bucket containing >1 trips
flagged_round_trips AS (
  SELECT
    end_station_id,
    CASE
      WHEN COUNT(*) OVER (PARTITION BY end_station_id, bucket_2min) > 1
      THEN 1 ELSE 0
    END AS is_group_trip
  FROM round_trips
),

-- Count group-ride trips per station
group_counts AS (
  SELECT
    end_station_id,
    SUM(is_group_trip) AS group_trips
  FROM flagged_round_trips
  GROUP BY end_station_id
),

-- Count all trips ending at each station
end_counts AS (
  SELECT
    end_station_id,
    COUNT(*) AS total_trips_ending
  FROM all_trips
  GROUP BY end_station_id
)

SELECT
  CAST(e.end_station_id AS INT64)                         AS station_id,
  SAFE_DIVIDE(g.group_trips, e.total_trips_ending)        AS group_ride_ratio,
  g.group_trips,
  e.total_trips_ending
FROM end_counts e
JOIN group_counts g USING (end_station_id)
ORDER BY group_ride_ratio DESC
LIMIT 10;