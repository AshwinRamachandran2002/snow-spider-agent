WITH total_stations AS (
  SELECT borough_name, COUNT(DISTINCT station_id) AS Total_Stations
  FROM `bigquery-public-data.new_york_subway.stations`
  GROUP BY borough_name
),
ada_stations AS (
  SELECT s.borough_name, COUNT(DISTINCT s.station_id) AS ADA_Stations
  FROM `bigquery-public-data.new_york_subway.stations` AS s
  JOIN (
    SELECT DISTINCT station_name
    FROM `bigquery-public-data.new_york_subway.station_entrances`
    WHERE entry = TRUE AND ada_compliant = TRUE
  ) AS se
  ON s.station_name = se.station_name
  GROUP BY s.borough_name
)
SELECT 
  t.borough_name AS Borough, 
  t.Total_Stations, 
  COALESCE(a.ADA_Stations, 0) AS ADA_Stations,
  ROUND(COALESCE(a.ADA_Stations, 0) / t.Total_Stations * 100, 4) AS Percentage
FROM total_stations t
LEFT JOIN ada_stations a
ON t.borough_name = a.borough_name
ORDER BY Percentage DESC;