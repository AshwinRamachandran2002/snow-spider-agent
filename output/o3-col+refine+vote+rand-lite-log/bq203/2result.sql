WITH total_stations AS (
  SELECT
    borough_name,
    COUNT(DISTINCT station_id) AS total_stations
  FROM `bigquery-public-data.new_york_subway.stations`
  GROUP BY borough_name
),
ada_station_list AS (
  SELECT DISTINCT
    LOWER(station_name) AS station_name_norm
  FROM `bigquery-public-data.new_york_subway.station_entrances`
  WHERE entry = TRUE
    AND ada_compliant = TRUE
),
ada_counts AS (
  SELECT
    s.borough_name,
    COUNT(DISTINCT s.station_id) AS ada_stations
  FROM `bigquery-public-data.new_york_subway.stations` AS s
  JOIN ada_station_list AS a
    ON LOWER(s.station_name) = a.station_name_norm
  GROUP BY s.borough_name
)
SELECT
  t.borough_name,
  t.total_stations,
  COALESCE(a.ada_stations, 0) AS ada_stations,
  ROUND(100 * COALESCE(a.ada_stations, 0) / t.total_stations, 2) AS ada_percentage
FROM total_stations AS t
LEFT JOIN ada_counts AS a
  ON t.borough_name = a.borough_name
ORDER BY ada_percentage DESC;