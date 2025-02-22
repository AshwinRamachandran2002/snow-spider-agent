-- Task: For each borough in New York City, list the total number of unique subway stations, the number of these stations that have at least one entrance that is both an entry point and ADA-compliant, and calculate the percentage these represent of the total number of stations in each borough. Order the boroughs from the highest to lowest percentage.

WITH stations_n_entrances AS (
      SELECT borough_name, s.station_name, entry, ada_compliant
      FROM `bigquery-public-data.new_york_subway.stations` s
      JOIN `bigquery-public-data.new_york_subway.station_entrances` se
      ON s.station_name = se.station_name
)

SELECT se.borough_name,
       COUNT(DISTINCT se.station_name) AS num_stations,
       COUNT(DISTINCT adas.station_name) AS num_stations_w_compliant_entrance,
       (100 * COUNT(DISTINCT adas.station_name)) / COUNT(DISTINCT se.station_name) AS percent_compliant_stations
FROM `stations_n_entrances` se
LEFT JOIN `stations_n_entrances` adas
  ON se.station_name = adas.station_name
  AND adas.entry AND adas.ada_compliant
GROUP BY se.borough_name
ORDER BY percent_compliant_stations DESC