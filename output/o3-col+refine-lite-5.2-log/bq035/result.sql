-- Total distance travelled by every bike in the Bay Area Bike Share program
WITH trip_distances AS (
  SELECT
    t.bike_number,
    -- great‑circle distance between the trip’s start & end stations (in meters)
    ST_DISTANCE(
      ST_GEOGPOINT(ss.longitude, ss.latitude),
      ST_GEOGPOINT(es.longitude, es.latitude)
    ) AS meters_travelled
  FROM `bigquery-public-data.san_francisco.bikeshare_trips`     AS t
  JOIN `bigquery-public-data.san_francisco.bikeshare_stations`  AS ss
    ON t.start_station_id = ss.station_id          -- start‑station coords
  JOIN `bigquery-public-data.san_francisco.bikeshare_stations`  AS es
    ON t.end_station_id   = es.station_id          -- end‑station coords
)

SELECT
  bike_number,
  ROUND(SUM(meters_travelled) / 1609.34 , 4) AS total_miles,
  ROUND(SUM(meters_travelled) / 1000.00 , 4) AS total_kilometers
FROM trip_distances
GROUP BY bike_number
ORDER BY total_miles DESC, bike_number;