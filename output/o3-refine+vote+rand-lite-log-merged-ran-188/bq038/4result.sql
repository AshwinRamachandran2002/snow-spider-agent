-- Top 10 Citi Bike stations by highest proportion of “group rides”
-- (round‑trips whose departures occur in 2‑minute windows with ≥2 riders)

WITH same_station_trips AS (      -- round‑trips (start = end)
  SELECT
    CAST(start_station_id AS STRING)           AS station_id,
    starttime,
    end_station_id,                            -- keep for later join
    FLOOR(UNIX_SECONDS(starttime)/120) AS time_bin   -- 2‑minute bucket
  FROM `bigquery-public-data.new_york.citibike_trips`
  WHERE start_station_id IS NOT NULL
    AND end_station_id   IS NOT NULL
    AND start_station_id =  end_station_id
),

group_bins AS (                   -- 2‑minute buckets with ≥2 trips
  SELECT station_id, time_bin
  FROM same_station_trips
  GROUP BY station_id, time_bin
  HAVING COUNT(*) >= 2
),

group_trips AS (                  -- all trips that are part of a group ride
  SELECT t.station_id, t.end_station_id
  FROM same_station_trips t
  JOIN group_bins g
  ON t.station_id = g.station_id
 AND t.time_bin   = g.time_bin
),

total_counts AS (                 -- total trips ending at each station
  SELECT CAST(end_station_id AS STRING) AS station_id,
         COUNT(*)                       AS total_trips
  FROM `bigquery-public-data.new_york.citibike_trips`
  WHERE end_station_id IS NOT NULL
  GROUP BY station_id
),

group_counts AS (                 -- number of group‑ride trips ending at station
  SELECT CAST(end_station_id AS STRING) AS station_id,
         COUNT(*)                       AS group_trips
  FROM group_trips
  GROUP BY station_id
),

proportions AS (
  SELECT
    t.station_id,
    COALESCE(g.group_trips, 0)            AS group_trips,
    t.total_trips,
    COALESCE(g.group_trips, 0) / t.total_trips AS proportion
  FROM total_counts t
  LEFT JOIN group_counts g USING (station_id)
),

with_names AS (                   -- attach station names (if available)
  SELECT
    p.station_id,
    s.name                        AS station_name,
    p.group_trips,
    p.total_trips,
    p.proportion
  FROM proportions p
  LEFT JOIN `bigquery-public-data.new_york.citibike_stations` s
         ON p.station_id = s.station_id
)

SELECT
  station_id,
  station_name,
  group_trips,
  total_trips,
  ROUND(proportion, 4) AS proportion
FROM with_names
ORDER BY proportion DESC, total_trips DESC
LIMIT 10;