WITH total_stations AS (
  SELECT borough_name, COUNT(DISTINCT station_id) AS total_stations
  FROM `bigquery-public-data.new_york_subway.stations`
  GROUP BY borough_name
),
ada_stations AS (
  SELECT s.borough_name, COUNT(DISTINCT s.station_id) AS ada_stations
  FROM `bigquery-public-data.new_york_subway.stations` s
  JOIN (
    SELECT DISTINCT station_name
    FROM `bigquery-public-data.new_york_subway.station_entrances`
    WHERE ada_compliant = TRUE
  ) ada
  ON s.station_name = ada.station_name
  GROUP BY s.borough_name
)
SELECT
  total_stations.borough_name,
  COALESCE(ROUND((ada_stations.ada_stations / total_stations.total_stations) * 100, 4), 0) AS percentage_of_ada_stations
FROM total_stations
LEFT JOIN ada_stations ON total_stations.borough_name = ada_stations.borough_name
ORDER BY
  CASE
    WHEN total_stations.borough_name = 'Manhattan' THEN 1
    WHEN total_stations.borough_name = 'Brooklyn' THEN 2
    WHEN total_stations.borough_name = 'Queens' THEN 3
    WHEN total_stations.borough_name = 'Bronx' THEN 4
    WHEN total_stations.borough_name = 'Staten Island' THEN 5
    ELSE 6
  END;