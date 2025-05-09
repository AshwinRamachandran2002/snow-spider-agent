/* Total distance (in kilometres) travelled by every bike in the Bay Area
   Bike Share system.  Distance for each trip is the great‑circle
   distance between the start‑ and end‑station coordinates; these are then
   summed per bike_number. */

WITH stations AS (
  SELECT
    station_id,
    longitude,
    latitude
  FROM `bigquery-public-data.san_francisco.bikeshare_stations`
),

trip_distances AS (
  SELECT
    t.bike_number,
    -- convert metres→km
    ST_DISTANCE(
      ST_GEOGPOINT(ss.longitude, ss.latitude),
      ST_GEOGPOINT(se.longitude, se.latitude)
    ) / 1000.0 AS trip_km
  FROM `bigquery-public-data.san_francisco.bikeshare_trips` AS t
  JOIN stations AS ss
    ON t.start_station_id = ss.station_id           -- start station
  JOIN stations AS se
    ON t.end_station_id   = se.station_id           -- end station
)

SELECT
  bike_number,
  ROUND(SUM(trip_km), 3) AS total_distance_km
FROM trip_distances
GROUP BY bike_number
ORDER BY total_distance_km DESC;