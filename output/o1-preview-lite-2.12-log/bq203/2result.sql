SELECT
  s.borough_name AS Borough,
  COUNT(DISTINCT s.station_id) AS Total_Stations,
  COUNT(DISTINCT CASE WHEN e.entry = TRUE AND e.ada_compliant = TRUE THEN s.station_id END) AS ADA_Stations,
  ROUND(COUNT(DISTINCT CASE WHEN e.entry = TRUE AND e.ada_compliant = TRUE THEN s.station_id END) / COUNT(DISTINCT s.station_id) * 100, 4) AS Percentage
FROM `bigquery-public-data.new_york_subway.stations` AS s
LEFT JOIN `bigquery-public-data.new_york_subway.station_entrances` AS e
  ON ST_DISTANCE(
    ST_GEOGPOINT(s.station_lon, s.station_lat),
    ST_GEOGPOINT(e.entrance_lon, e.entrance_lat)
  ) < 100
WHERE s.borough_name IS NOT NULL
GROUP BY s.borough_name
ORDER BY Percentage DESC;