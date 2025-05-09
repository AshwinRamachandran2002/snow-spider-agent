WITH berkeley_stations AS (
  SELECT station_id
  FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info`
  WHERE region_id = 14
),
trip_metrics AS (
  SELECT
    t.trip_id,
    ST_DISTANCE(
      ST_GEOGPOINT(start.lon, start.lat),
      ST_GEOGPOINT(finish.lon, finish.lat)
    )           AS trip_distance_m,
    t.duration_sec,
    ST_DISTANCE(
      ST_GEOGPOINT(start.lon, start.lat),
      ST_GEOGPOINT(finish.lon, finish.lat)
    ) / t.duration_sec AS avg_speed_m_s
  FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips` t
  JOIN `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info` start
    ON CAST(t.start_station_id AS STRING) = start.station_id
  JOIN `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info` finish
    ON CAST(t.end_station_id   AS STRING) = finish.station_id
  WHERE start.region_id = 14 OR finish.region_id = 14          -- Berkeley involvement
)
SELECT
  ROUND(MAX(avg_speed_m_s), 1) AS highest_avg_speed_m_s
FROM trip_metrics
WHERE trip_distance_m > 1000       -- trips longer than 1 km
  AND duration_sec   > 0;          -- guard against divide-by-zero