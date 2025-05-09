-- highest average speed (m/s) for Berkeley bike-share trips whose straight-line
-- distance between start & end stations is > 1000 m
WITH berkeley_stations AS (
  SELECT station_id
  FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info`
  WHERE region_id = 14                           -- 14 = Berkeley
),
trip_distances AS (
  SELECT
    duration_sec,
    ST_DISTANCE(start_station_geom, end_station_geom) AS dist_m
  FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips`
  WHERE start_station_geom IS NOT NULL
    AND end_station_geom   IS NOT NULL
    AND CAST(start_station_id AS STRING) IN (SELECT station_id FROM berkeley_stations)
    AND CAST(end_station_id   AS STRING) IN (SELECT station_id FROM berkeley_stations)
    AND ST_DISTANCE(start_station_geom, end_station_geom) > 1000   -- distance filter
)
SELECT
  ROUND(MAX(dist_m / duration_sec), 1) AS highest_avg_speed_mps
FROM trip_distances;