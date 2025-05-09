-- ADA-accessible vs. total subway stations by NYC borough
WITH ada_station_ids AS (
  -- all stations that have at least one entrance
  -- which is both an entry point and ADA-compliant
  SELECT DISTINCT s.station_id
  FROM `bigquery-public-data.new_york_subway.station_entrances` AS e
  JOIN `bigquery-public-data.new_york_subway.stations`          AS s
    ON LOWER(e.station_name) = LOWER(s.station_name)
  WHERE e.entry = TRUE
    AND e.ada_compliant = TRUE
),
total_per_borough AS (
  SELECT
    borough_name,
    COUNT(DISTINCT station_id) AS total_stations
  FROM `bigquery-public-data.new_york_subway.stations`
  GROUP BY borough_name
),
ada_per_borough AS (
  SELECT
    s.borough_name,
    COUNT(DISTINCT s.station_id) AS ada_stations
  FROM `bigquery-public-data.new_york_subway.stations` AS s
  WHERE s.station_id IN (SELECT station_id FROM ada_station_ids)
  GROUP BY s.borough_name
)

SELECT
  t.borough_name,
  COALESCE(a.ada_stations, 0)                     AS ada_stations,
  t.total_stations,
  ROUND(100 * COALESCE(a.ada_stations, 0) / t.total_stations, 2) AS ada_percent
FROM total_per_borough t
LEFT JOIN ada_per_borough a USING (borough_name)
ORDER BY ada_percent DESC;