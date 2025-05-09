-- Total distance (in kilometers) ridden by every bike in the SF Bikeshare program
SELECT
  t.bike_number,
  ROUND(
    SUM(
      ST_DISTANCE(
        ST_GEOGPOINT(ss.longitude, ss.latitude),  -- start station
        ST_GEOGPOINT(es.longitude, es.latitude)   -- end station
      ) / 1000                                   -- convert metres → km
    )
  , 2) AS total_distance_km
FROM `bigquery-public-data.san_francisco.bikeshare_trips`     AS t
JOIN `bigquery-public-data.san_francisco.bikeshare_stations`  AS ss
  ON t.start_station_id = ss.station_id
JOIN `bigquery-public-data.san_francisco.bikeshare_stations`  AS es
  ON t.end_station_id   = es.station_id
WHERE ss.longitude IS NOT NULL
  AND ss.latitude  IS NOT NULL
  AND es.longitude IS NOT NULL
  AND es.latitude  IS NOT NULL
GROUP BY t.bike_number
ORDER BY t.bike_number;