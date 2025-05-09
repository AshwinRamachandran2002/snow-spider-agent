-- Top-10 Citi Bike stations with the highest share of “group rides”
WITH loops AS (        -- trips that start & end at the same station
  SELECT
    start_station_id,
    DIV(UNIX_SECONDS(starttime), 120) AS win   -- 2-minute window id
  FROM `bigquery-public-data.new_york.citibike_trips`
  WHERE start_station_id = end_station_id
),
windows AS (           -- windows containing ≥ 2 such trips
  SELECT
    start_station_id   AS station_id,
    win
  FROM loops
  GROUP BY station_id, win
  HAVING COUNT(*) >= 2
),
group_trips AS (       -- every loop-trip that falls in a qualifying window
  SELECT l.start_station_id
  FROM loops   AS l
  JOIN windows AS w
    ON l.start_station_id = w.station_id
   AND l.win             = w.win
),
grp_cnt AS (           -- numerator: # group-rides per station
  SELECT
    start_station_id AS station_id,
    COUNT(*)         AS group_trip_cnt
  FROM group_trips
  GROUP BY station_id
),
end_cnt AS (           -- denominator: total trips that END at each station
  SELECT
    end_station_id AS station_id,
    COUNT(*)       AS total_end_trips
  FROM `bigquery-public-data.new_york.citibike_trips`
  GROUP BY station_id
),
proportions AS (       -- share of group-rides per station
  SELECT
    e.station_id,
    SAFE_DIVIDE(g.group_trip_cnt, e.total_end_trips) AS group_prop,
    g.group_trip_cnt,
    e.total_end_trips
  FROM end_cnt AS e
  LEFT JOIN grp_cnt AS g USING (station_id)
  WHERE e.total_end_trips >= 50            -- filter out very small stations
)
SELECT
  p.station_id,
  s.name                            AS station_name,
  ROUND(p.group_prop, 4)            AS group_ride_proportion,
  p.group_trip_cnt                  AS group_trips,
  p.total_end_trips                 AS total_trips_end
FROM proportions AS p
LEFT JOIN `bigquery-public-data.new_york.citibike_stations` AS s
  ON s.station_id = CAST(p.station_id AS STRING)      -- INT64 → STRING
ORDER BY group_ride_proportion DESC
LIMIT 10;