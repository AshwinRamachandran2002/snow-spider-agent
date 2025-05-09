-- Top-10 Citi Bike stations by share of “group-ride” trips
WITH
/* 1) Same-station trips bucketed into 2-minute windows */
same_station AS (
  SELECT
    start_station_id                           AS station_id,
    TIMESTAMP_SECONDS( 120 *
      DIV(UNIX_SECONDS(starttime), 120) )      AS window_start
  FROM `bigquery-public-data.new_york.citibike_trips`
  WHERE start_station_id = end_station_id
),

/* 2) Keep only windows that contain >1 trip (i.e., a group ride) */
windows AS (
  SELECT
    station_id,
    window_start,
    COUNT(*) AS trips_in_window
  FROM same_station
  GROUP BY station_id, window_start
  HAVING COUNT(*) > 1
),

/* 3) Sum all trips that belong to such windows → group-ride trips */
group_counts AS (
  SELECT
    station_id,
    SUM(trips_in_window) AS group_trips          -- numerator
  FROM windows
  GROUP BY station_id
),

/* 4) Total trips ending at each station → denominator */
total_end AS (
  SELECT
    end_station_id AS station_id,
    COUNT(*)       AS total_end_trips
  FROM `bigquery-public-data.new_york.citibike_trips`
  GROUP BY station_id
)

/* 5) Calculate proportion and attach human-readable station name */
SELECT
  COALESCE(s.name, CONCAT('[ID ', CAST(t.station_id AS STRING), ']'))
      AS station_name,
  g.group_trips,
  t.total_end_trips,
  ROUND(SAFE_DIVIDE(g.group_trips, t.total_end_trips), 4) AS group_ratio
FROM total_end t
JOIN group_counts g USING (station_id)
LEFT JOIN `bigquery-public-data.new_york.citibike_stations`  s
       ON s.station_id = CAST(t.station_id AS STRING)
ORDER BY group_ratio DESC
LIMIT 10;