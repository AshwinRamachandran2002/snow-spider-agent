-- Task: For each New York City borough, how many subway stations have at least one entrance that is both an actual entry and ADA-compliant, listing boroughs from highest to lowest number of such stations
SELECT adas.borough_name, COUNT(DISTINCT adas.station_name) AS num_stations_w_compliant_entrance
FROM (
      SELECT borough_name, s.station_name, entry, ada_compliant
      FROM `bigquery-public-data.new_york_subway.stations` s
      JOIN `bigquery-public-data.new_york_subway.station_entrances` se
      ON s.station_name = se.station_name
    ) adas
WHERE adas.entry AND adas.ada_compliant
GROUP BY adas.borough_name
ORDER BY num_stations_w_compliant_entrance DESC