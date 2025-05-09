-- ADA-accessible subway-station coverage by borough
WITH ada_station_names AS (
  SELECT DISTINCT LOWER(station_name) AS station_name_lc
  FROM `bigquery-public-data.new_york_subway.station_entrances`
  WHERE entry = TRUE               -- it is a usable entrance
    AND ada_compliant = TRUE       -- and ADA-compliant
),
total AS (
  SELECT borough_name,
         COUNT(DISTINCT station_id) AS total_stations
  FROM `bigquery-public-data.new_york_subway.stations`
  GROUP BY borough_name
),
ada AS (
  SELECT s.borough_name,
         COUNT(DISTINCT s.station_id) AS ada_stations
  FROM `bigquery-public-data.new_york_subway.stations` AS s
  JOIN ada_station_names AS a
    ON LOWER(s.station_name) = a.station_name_lc
  GROUP BY s.borough_name
)
SELECT
  t.borough_name,
  t.total_stations,
  IFNULL(a.ada_stations, 0) AS ada_stations,
  ROUND(IFNULL(a.ada_stations,0) * 100.0 / t.total_stations, 2) AS pct_accessible
FROM total AS t
LEFT JOIN ada AS a
  ON t.borough_name = a.borough_name
ORDER BY pct_accessible DESC;