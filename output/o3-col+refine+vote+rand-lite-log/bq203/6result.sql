-- Borough-level subway-station ADA accessibility
WITH ada_stations AS (
  -- stations that have ≥1 entrance that is BOTH an entry point AND ADA-compliant
  SELECT DISTINCT
         s.station_id,
         s.borough_name
  FROM `bigquery-public-data.new_york_subway.stations`          AS s
  JOIN `bigquery-public-data.new_york_subway.station_entrances` AS e
       ON LOWER(s.station_name) = LOWER(e.station_name)
  WHERE e.entry = TRUE
    AND e.ada_compliant = TRUE
),
total_stations AS (
  SELECT
    borough_name,
    COUNT(DISTINCT station_id) AS total_stations
  FROM `bigquery-public-data.new_york_subway.stations`
  GROUP BY borough_name
),
ada_counts AS (
  SELECT
    borough_name,
    COUNT(DISTINCT station_id) AS ada_entry_stations
  FROM ada_stations
  GROUP BY borough_name
)
SELECT
  t.borough_name                     AS borough,
  t.total_stations,
  COALESCE(a.ada_entry_stations, 0)  AS ada_entry_stations,
  ROUND( COALESCE(a.ada_entry_stations, 0) / t.total_stations * 100 , 2)
                                      AS percent_of_total
FROM total_stations t
LEFT JOIN ada_counts a USING (borough_name)
ORDER BY percent_of_total DESC;