WITH trips_in_berkeley AS (
  SELECT
    t.trip_id,
    -- distance in metres between start and end points
    ST_DISTANCE(
      COALESCE(t.start_station_geom,
               ST_GEOGPOINT(t.start_station_longitude, t.start_station_latitude)),
      COALESCE(t.end_station_geom,
               ST_GEOGPOINT(t.end_station_longitude, t.end_station_latitude))
    ) AS distance_m,
    t.duration_sec
  FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips` AS t
  JOIN `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info` AS s_start
    ON CAST(t.start_station_id AS STRING) = s_start.station_id
  JOIN `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info` AS s_end
    ON CAST(t.end_station_id AS STRING) = s_end.station_id
  -- Berkeley’s region_id is 14
  WHERE (s_start.region_id = 14 OR s_end.region_id = 14)
    AND t.duration_sec > 0
),
speeds AS (
  SELECT
    trip_id,
    distance_m,
    duration_sec,
    distance_m / duration_sec AS speed_mps          -- average speed
  FROM trips_in_berkeley
  WHERE distance_m > 1000                           -- only trips > 1 km
)
SELECT
  ROUND(MAX(speed_mps), 1) AS highest_average_speed_mps
FROM speeds;