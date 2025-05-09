WITH loop_trips AS (        -- trips that start & end at the same dock, bucketed in 2‑min windows
  SELECT
    start_station_id AS station_id,
    TIMESTAMP_SECONDS(120 * DIV(UNIX_SECONDS(starttime), 120)) AS bucket_start,
    COUNT(*) OVER (
      PARTITION BY start_station_id,
                   TIMESTAMP_SECONDS(120 * DIV(UNIX_SECONDS(starttime), 120))
    ) AS trips_in_bucket
  FROM `bigquery-public-data.new_york.citibike_trips`
  WHERE start_station_id = end_station_id
),
group_trip_counts AS (      -- numerator: every trip that is in a bucket with ≥2 rides
  SELECT
    station_id,
    COUNTIF(trips_in_bucket > 1) AS group_trip_cnt
  FROM loop_trips
  GROUP BY station_id
),
total_trip_counts AS (      -- denominator: all trips that end at the station
  SELECT
    end_station_id AS station_id,
    COUNT(*) AS total_trip_cnt
  FROM `bigquery-public-data.new_york.citibike_trips`
  GROUP BY station_id
),
proportions AS (
  SELECT
    t.station_id,
    SAFE_DIVIDE(g.group_trip_cnt, t.total_trip_cnt) AS proportion
  FROM total_trip_counts t
  JOIN group_trip_counts g USING (station_id)
)
SELECT
  p.station_id,
  COALESCE(s.name, CAST(p.station_id AS STRING)) AS station_name,
  ROUND(p.proportion, 4) AS group_ride_proportion
FROM proportions p
LEFT JOIN `bigquery-public-data.new_york.citibike_stations` s
  ON s.station_id = CAST(p.station_id AS STRING)
ORDER BY group_ride_proportion DESC, station_id
LIMIT 10;