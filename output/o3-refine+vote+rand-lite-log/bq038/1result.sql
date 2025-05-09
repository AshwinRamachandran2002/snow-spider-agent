-- top 10 Citi Bike stations by share of “group rides”
WITH
/* 1.  trips that start and finish at the same station */
same_station AS (
  SELECT
    start_station_id         AS station_id,
    starttime
  FROM `bigquery-public-data.new_york.citibike_trips`
  WHERE start_station_id IS NOT NULL
    AND end_station_id   IS NOT NULL
    AND start_station_id = end_station_id
),

/* 2.  place every departure in a 2‑minute bucket             */
bucketed AS (
  SELECT
    station_id,
    starttime,
    FLOOR(UNIX_SECONDS(starttime) / 120) AS bucket_2min
  FROM same_station
),

/* 3.  flag every trip that shares its (station , 2‑min bucket) 
        with at least one other trip → it belongs to a group   */
group_flagged AS (
  SELECT
    station_id
  FROM (
    SELECT
      station_id,
      bucket_2min,
      COUNT(*) AS trips_in_bucket
    FROM bucketed
    GROUP BY station_id, bucket_2min
    HAVING COUNT(*) >= 2          -- at least two riders together
  ) gf
  JOIN bucketed b
  USING (station_id, bucket_2min) -- explode back to individual trips
),

/* 4.  count group‑ride trips per station                      */
group_counts AS (
  SELECT
    station_id,
    COUNT(*) AS group_trip_cnt
  FROM group_flagged
  GROUP BY station_id
),

/* 5.  total trips that END at each station (denominator)      */
total_counts AS (
  SELECT
    end_station_id AS station_id,
    COUNT(*)       AS total_trip_cnt
  FROM `bigquery-public-data.new_york.citibike_trips`
  WHERE end_station_id IS NOT NULL
  GROUP BY station_id
),

/* 6.  proportions                                             */
proportions AS (
  SELECT
    t.station_id,
    COALESCE(g.group_trip_cnt,0) AS group_trip_cnt,
    t.total_trip_cnt,
    SAFE_DIVIDE(COALESCE(g.group_trip_cnt,0), t.total_trip_cnt) AS proportion
  FROM total_counts t
  LEFT JOIN group_counts g USING (station_id)
  WHERE t.total_trip_cnt > 0
),

/* 7.  enrich with human‑readable station name                 */
with_names AS (
  SELECT
    p.station_id,
    cs.name                           AS station_name,
    p.group_trip_cnt,
    p.total_trip_cnt,
    p.proportion
  FROM proportions p
  LEFT JOIN `bigquery-public-data.new_york.citibike_stations` cs
         ON cs.station_id = CAST(p.station_id AS STRING)
)

SELECT
  station_id,
  station_name,
  ROUND(proportion,4) AS proportion
FROM with_names
WHERE group_trip_cnt > 0
ORDER BY proportion DESC, station_id
LIMIT 10;