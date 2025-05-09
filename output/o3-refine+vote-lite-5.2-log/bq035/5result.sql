-- Total distance (in kilometers) traveled by every bike in the Bay Area
-- Bikeshare program, computed as the great‑circle distance between the
-- start and end stations of every trip and then aggregated per bike.

WITH trip_distances AS (
  SELECT
    t.bike_number,
    -- Great‑circle distance between the two stations (meters ÷ 1 000 ⇒ km)
    ST_DISTANCE(
      ST_GEOGPOINT(ss.longitude, ss.latitude),
      ST_GEOGPOINT(es.longitude, es.latitude)
    ) / 1000 AS trip_distance_km
  FROM `bigquery-public-data.san_francisco.bikeshare_trips`    AS t
  JOIN `bigquery-public-data.san_francisco.bikeshare_stations` AS ss
       ON t.start_station_id = ss.station_id                  -- start station
  JOIN `bigquery-public-data.san_francisco.bikeshare_stations` AS es
       ON t.end_station_id   = es.station_id                  -- end station
)

SELECT
  bike_number,
  ROUND(SUM(trip_distance_km), 2) AS total_distance_km
FROM trip_distances
GROUP BY bike_number
ORDER BY total_distance_km DESC;