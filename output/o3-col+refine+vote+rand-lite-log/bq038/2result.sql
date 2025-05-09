-- Top-10 Citi Bike stations by share of “group rides”
-- • “Group ride” = round-trip (same start & end station) where ≥2 trips start in the same 2-minute window
-- • Proportion = group-ride trips ÷ all trips that end at that station
WITH round_trips AS (          -- round-trips only, bucketed into 2-minute windows
  SELECT
    end_station_id AS station_id,
    TIMESTAMP_SECONDS(120 * DIV(UNIX_SECONDS(starttime), 120)) AS bucket_2min
  FROM `bigquery-public-data.new_york.citibike_trips`
  WHERE start_station_id = end_station_id
),
flagged AS (                    -- mark every round-trip that belongs to a “group” bucket
  SELECT
    station_id,
    CASE
      WHEN COUNT(*) OVER (PARTITION BY station_id, bucket_2min) >= 2 THEN 1
      ELSE 0
    END AS is_group
  FROM round_trips
),
group_counts AS (               -- how many trips are part of a group at each station
  SELECT
    station_id,
    SUM(is_group) AS group_trip_cnt
  FROM flagged
  GROUP BY station_id
),
total_counts AS (               -- total trips ending at each station (denominator)
  SELECT
    end_station_id AS station_id,
    COUNT(*)       AS total_trips
  FROM `bigquery-public-data.new_york.citibike_trips`
  GROUP BY station_id
),
proportions AS (                -- compute the share of group rides
  SELECT
    g.station_id,
    SAFE_DIVIDE(g.group_trip_cnt, t.total_trips) AS group_prop,
    g.group_trip_cnt,
    t.total_trips
  FROM group_counts g
  JOIN total_counts t USING (station_id)
)
SELECT
  COALESCE(s.name, CONCAT('Station ', CAST(p.station_id AS STRING))) AS station_name,
  ROUND(p.group_prop, 4) AS group_proportion,
  p.group_trip_cnt,
  p.total_trips
FROM proportions p
LEFT JOIN `bigquery-public-data.new_york.citibike_stations` s
       ON s.station_id = CAST(p.station_id AS STRING)   -- station_id in stations table is STRING
ORDER BY group_proportion DESC
LIMIT 10;