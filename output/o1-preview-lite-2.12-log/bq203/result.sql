SELECT
  total.borough_name AS Borough,
  total.total_stations AS Total_Stations,
  COALESCE(ada.ada_stations, 0) AS ADA_Stations,
  ROUND((COALESCE(ada.ada_stations, 0) / total.total_stations) * 100, 4) AS Percentage
FROM (
  SELECT
    borough_name,
    COUNT(DISTINCT station_id) AS total_stations
  FROM `bigquery-public-data.new_york_subway.stations`
  WHERE borough_name IS NOT NULL
  GROUP BY borough_name
) AS total
LEFT JOIN (
  SELECT
    s.borough_name,
    COUNT(DISTINCT s.station_id) AS ada_stations
  FROM `bigquery-public-data.new_york_subway.stations` AS s
  JOIN `bigquery-public-data.new_york_subway.station_entrances` AS se
  ON LOWER(TRIM(s.station_name)) = LOWER(TRIM(se.station_name))
  WHERE se.entry = TRUE AND se.ada_compliant = TRUE
    AND s.station_name IS NOT NULL AND se.station_name IS NOT NULL
  GROUP BY s.borough_name
) AS ada
ON total.borough_name = ada.borough_name
ORDER BY Percentage DESC;