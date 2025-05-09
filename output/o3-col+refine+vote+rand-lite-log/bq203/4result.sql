WITH ada_entry_station_names AS (
  -- every station name that has at least one entrance that is BOTH an entry
  -- and ADA-compliant
  SELECT DISTINCT station_name
  FROM `bigquery-public-data.new_york_subway.station_entrances`
  WHERE entry = TRUE
    AND ada_compliant = TRUE
),

total_stations_per_borough AS (
  SELECT
    borough_name,
    COUNT(DISTINCT station_id) AS total_stations
  FROM `bigquery-public-data.new_york_subway.stations`
  GROUP BY borough_name
),

ada_stations_per_borough AS (
  SELECT
    s.borough_name,
    COUNT(DISTINCT s.station_id) AS ada_stations
  FROM `bigquery-public-data.new_york_subway.stations` AS s
  JOIN ada_entry_station_names AS a
    ON s.station_name = a.station_name
  GROUP BY s.borough_name
)

SELECT
  t.borough_name,
  t.total_stations,
  COALESCE(a.ada_stations, 0)        AS ada_stations,
  ROUND( COALESCE(a.ada_stations,0) * 100.0 / t.total_stations , 2) AS pct_accessible
FROM total_stations_per_borough AS t
LEFT JOIN ada_stations_per_borough AS a
  ON t.borough_name = a.borough_name
ORDER BY pct_accessible DESC;