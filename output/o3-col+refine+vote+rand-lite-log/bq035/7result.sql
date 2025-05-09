-- Total distance (in miles) traveled by every bike in the SF Bikeshare program
SELECT
  t.bike_number,
  ROUND(
    SUM(
      ST_DISTANCE(
        ST_GEOGPOINT(ss.longitude, ss.latitude),
        ST_GEOGPOINT(es.longitude, es.latitude)
      )
    ) / 1609.34,                 -- meters → miles
    4
  ) AS total_distance_miles
FROM `bigquery-public-data.san_francisco.bikeshare_trips`     AS t
JOIN `bigquery-public-data.san_francisco.bikeshare_stations`  AS ss
  ON t.start_station_id = ss.station_id
JOIN `bigquery-public-data.san_francisco.bikeshare_stations`  AS es
  ON t.end_station_id   = es.station_id
GROUP BY t.bike_number
ORDER BY total_distance_miles DESC;