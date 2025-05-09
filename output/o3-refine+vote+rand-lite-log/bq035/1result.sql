-- Total distance (in kilometers) travelled by every bike in the Bay Area
-- Bikeshare system, computed from trip start / end points.

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
    -- distance for this trip in meters
    ST_DISTANCE(
      ST_GEOGPOINT(s_start.longitude, s_start.latitude),
      ST_GEOGPOINT(s_end.longitude,   s_end.latitude)
    ) AS trip_distance_meters
  FROM
    `bigquery-public-data.san_francisco.bikeshare_trips` AS t
  JOIN
    station_coords AS s_start
  ON  t.start_station_id = s_start.station_id
  JOIN
    station_coords AS s_end
  ON  t.end_station_id   = s_end.station_id
)

SELECT
  bike_number,
  ROUND(SUM(trip_distance_meters) / 1000, 2) AS total_distance_km
FROM
  trip_distances
GROUP BY
  bike_number
ORDER BY
  total_distance_km DESC, bike_number;