-- Total straight-line (great-circle) distance travelled by each bike
WITH trip_segments AS (
  SELECT
    t.bike_number,
    ST_GEOGPOINT(ss.longitude, ss.latitude) AS start_pt,
    ST_GEOGPOINT(es.longitude, es.latitude) AS end_pt
  FROM `bigquery-public-data.san_francisco.bikeshare_trips`    AS t
  JOIN `bigquery-public-data.san_francisco.bikeshare_stations` AS ss
    ON t.start_station_id = ss.station_id
  JOIN `bigquery-public-data.san_francisco.bikeshare_stations` AS es
    ON t.end_station_id   = es.station_id
)

SELECT
  bike_number,
  ROUND( SUM( ST_DISTANCE(start_pt, end_pt) ) / 1000 , 2 ) AS total_distance_km
FROM trip_segments
GROUP BY bike_number
ORDER BY total_distance_km DESC;