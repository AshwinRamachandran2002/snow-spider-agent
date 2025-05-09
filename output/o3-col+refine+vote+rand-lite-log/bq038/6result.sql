-- Top-10 Citi Bike stations by proportion of “group rides”
-- (≥2 trips that start AND end at the same station within the same 2-minute window)

WITH loop_trips AS (               -- trips that start & end at same station
  SELECT
    start_station_id,
    TIMESTAMP_SECONDS(              -- bucket start-times into 2-minute windows
      UNIX_SECONDS(starttime) - MOD(UNIX_SECONDS(starttime), 120)
    ) AS win_start
  FROM `bigquery-public-data.new_york.citibike_trips`
  WHERE start_station_id = end_station_id
),
qual_windows AS (                  -- windows that actually have a “group” (≥2 trips)
  SELECT
    start_station_id,
    win_start,
    COUNT(*) AS trips_in_window
  FROM loop_trips
  GROUP BY start_station_id, win_start
  HAVING trips_in_window > 1
),
group_trip_counts AS (             -- numerator: all trips that belong to a qualifying window
  SELECT
    l.start_station_id,
    COUNT(*) AS group_trip_cnt
  FROM loop_trips AS l
  JOIN qual_windows AS q
  USING (start_station_id, win_start)
  GROUP BY l.start_station_id
),
total_end_counts AS (              -- denominator: every trip that ENDS at each station
  SELECT
    end_station_id AS station_id,
    COUNT(*)       AS total_end_trips
  FROM `bigquery-public-data.new_york.citibike_trips`
  GROUP BY station_id
),
proportions AS (
  SELECT
    t.station_id,
    g.group_trip_cnt,
    t.total_end_trips,
    SAFE_DIVIDE(g.group_trip_cnt, t.total_end_trips) AS group_prop
  FROM total_end_counts AS t
  JOIN group_trip_counts AS g
  ON t.station_id = g.start_station_id
)
SELECT
  p.station_id,
  s.name                         AS station_name,
  p.group_trip_cnt,
  p.total_end_trips,
  ROUND(p.group_prop, 4)         AS proportion_of_group_rides
FROM proportions AS p
JOIN `bigquery-public-data.new_york.citibike_stations` AS s
  ON s.station_id = CAST(p.station_id AS STRING)
ORDER BY proportion_of_group_rides DESC
LIMIT 10;