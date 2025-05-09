-- Total distance (in miles) traveled by every bike
WITH trip_distances AS (
  SELECT
    t.bike_number,
    -- great‐circle distance between start & end stations, converted to miles
    ST_DISTANCE(
      ST_GEOGPOINT(ss.longitude, ss.latitude),
      ST_GEOGPOINT(es.longitude, es.latitude)
    ) / 1609.34 AS miles_in_trip
  FROM `bigquery-public-data.san_francisco.bikeshare_trips`    AS t
  JOIN `bigquery-public-data.san_francisco.bikeshare_stations` AS ss
       ON t.start_station_id = ss.station_id
  JOIN `bigquery-public-data.san_francisco.bikeshare_stations` AS es
       ON t.end_station_id   = es.station_id
)

SELECT
  bike_number,
  ROUND(SUM(miles_in_trip), 2) AS total_miles_traveled
FROM trip_distances
GROUP BY bike_number
ORDER BY total_miles_traveled DESC;