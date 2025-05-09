SELECT
  ROUND(MAX(trip_distance_meters / duration_sec), 1) AS Highest_average_speed_meters_per_second
FROM (
  SELECT
    trip_id,
    duration_sec,
    ST_DISTANCE(
      ST_GEOGPOINT(start_station_longitude, start_station_latitude),
      ST_GEOGPOINT(end_station_longitude, end_station_latitude)
    ) AS trip_distance_meters
  FROM
    `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips`
  WHERE
    (
      CAST(start_station_id AS STRING) IN (
        SELECT station_id
        FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info`
        WHERE LOWER(name) LIKE '%berkeley%'
      )
      OR CAST(end_station_id AS STRING) IN (
        SELECT station_id
        FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info`
        WHERE LOWER(name) LIKE '%berkeley%'
      )
    )
    AND duration_sec > 0
    AND start_station_latitude IS NOT NULL
    AND start_station_longitude IS NOT NULL
    AND end_station_latitude IS NOT NULL
    AND end_station_longitude IS NOT NULL
)
WHERE trip_distance_meters > 1000;