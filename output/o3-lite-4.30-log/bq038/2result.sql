WITH base AS (
  SELECT
    start_station_id,
    end_station_id,
    TIMESTAMP_SECONDS(DIV(UNIX_SECONDS(starttime), 120) * 120) AS bucket_start
  FROM `bigquery-public-data.new_york.citibike_trips`
  WHERE end_station_id IS NOT NULL
),
self_trips AS (
  SELECT
    end_station_id AS station_id,
    bucket_start,
    COUNT(*) OVER (PARTITION BY end_station_id, bucket_start) AS bucket_size
  FROM base
  WHERE start_station_id = end_station_id
),
group_trips AS (
  SELECT
    station_id,
    COUNT(*) AS group_ride_trips
  FROM self_trips
  WHERE bucket_size > 1
  GROUP BY station_id
),
end_counts AS (
  SELECT
    end_station_id AS station_id,
    COUNT(*) AS total_end_trips
  FROM `bigquery-public-data.new_york.citibike_trips`
  GROUP BY station_id
),
proportions AS (
  SELECT
    e.station_id,
    IFNULL(g.group_ride_trips, 0) AS group_ride_trips,
    e.total_end_trips,
    SAFE_DIVIDE(IFNULL(g.group_ride_trips, 0), e.total_end_trips) AS group_ride_proportion
  FROM end_counts e
  LEFT JOIN group_trips g USING (station_id)
)
SELECT
  CAST(p.station_id AS STRING)  AS station_id,
  COALESCE(s.name, '')          AS station_name,
  ROUND(p.group_ride_proportion, 4) AS group_ride_proportion
FROM proportions p
LEFT JOIN `bigquery-public-data.new_york.citibike_stations` s
  ON s.station_id = CAST(p.station_id AS STRING)
ORDER BY group_ride_proportion DESC, station_id
LIMIT 10;