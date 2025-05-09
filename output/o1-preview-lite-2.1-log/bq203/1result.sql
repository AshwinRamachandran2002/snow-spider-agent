SELECT 
  s.borough_name AS borough_name,
  ROUND(
    COUNT(DISTINCT IF(e.ada_compliant = TRUE, s.station_id, NULL)) * 100.0 / COUNT(DISTINCT s.station_id)
  ,4) AS percentage_of_ada_stations
FROM 
  `bigquery-public-data.new_york_subway.stations` AS s
LEFT JOIN 
  `bigquery-public-data.new_york_subway.station_entrances` AS e
ON 
  s.station_name = e.station_name
GROUP BY 
  s.borough_name
ORDER BY
  s.borough_name;