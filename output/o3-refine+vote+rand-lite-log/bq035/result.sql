-- Total distance (in kilometers) traveled by each bike
WITH station_coords AS (
  SELECT
    station_id,
    latitude,
    longitude
  FROM
    `bigquery-public-data.san_francisco.bikeshare_stations`
),
trip_distances AS (
  SELECT
    t.bike_number,
    -- Haversine distance between start and end stations (return value is in meters)
    ST_DISTANCE(
      ST_GEOGPOINT(s_start.longitude, s_start.latitude),
      ST_GEOGPOINT(s_end.longitude,  s_end.latitude)
    ) / 1000 AS trip_km        -- convert meters to kilometers
  FROM
    `bigquery-public-data.san_francisco.bikeshare_trips` AS t
  JOIN
    station_coords AS s_start
  ON
    t.start_station_id = s_start.station_id
  JOIN
    station_coords AS s_end
  ON
    t.end_station_id = s_end.station_id
)
SELECT
  bike_number,
  ROUND(SUM(trip_km), 4) AS total_distance_km
FROM
  trip_distances
GROUP BY
  bike_number
ORDER BY
  total_distance_km DESC,
  bike_number;