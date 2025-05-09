/*  Stations with ADA‑compliant entry by borough */
WITH total AS (
  SELECT
    borough_name,
    COUNT(DISTINCT station_name) AS total_stations
  FROM `bigquery-public-data.new_york_subway.stations`
  GROUP BY borough_name
),
ada AS (
  SELECT
    s.borough_name,
    COUNT(DISTINCT s.station_name) AS ada_stations
  FROM `bigquery-public-data.new_york_subway.stations` AS s
  JOIN (
        SELECT DISTINCT LOWER(station_name) AS station_name_lower
        FROM `bigquery-public-data.new_york_subway.station_entrances`
        WHERE entry = TRUE
          AND ada_compliant = TRUE
       ) AS a
  ON LOWER(s.station_name) = a.station_name_lower
  GROUP BY s.borough_name
)

SELECT
  t.borough_name,
  t.total_stations,
  IFNULL(a.ada_stations, 0) AS ada_stations,
  ROUND(100 * IFNULL(a.ada_stations, 0) / t.total_stations, 2) AS ada_percent
FROM total AS t
LEFT JOIN ada AS a USING (borough_name)
ORDER BY ada_percent DESC, borough_name;