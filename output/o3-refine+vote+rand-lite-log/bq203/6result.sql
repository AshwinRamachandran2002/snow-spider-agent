WITH ada_stations AS (
  -- stations that have at least one *entrance* flagged as both an entry point and ADA‑compliant
  SELECT DISTINCT
         sc.complex_id
  FROM `bigquery-public-data.new_york_subway.station_entrances`  AS se
  JOIN `bigquery-public-data.new_york_subway.station_complexes`  AS sc
        ON se.station_name = sc.complex_name          -- maps entrance to station complex
  WHERE se.entry = TRUE
    AND se.ada_compliant = TRUE
),
all_stations AS (
  -- every subway station, identified by its complex_id and borough
  SELECT DISTINCT
         s.complex_id,
         s.borough_name
  FROM `bigquery-public-data.new_york_subway.stations` AS s
),
stations_flagged AS (
  -- mark each station as ADA‑accessible (via at least one compliant entrance) or not
  SELECT
         a.borough_name,
         a.complex_id,
         IF(ada.complex_id IS NOT NULL, 1, 0) AS is_ada
  FROM all_stations AS a
  LEFT JOIN ada_stations AS ada
         ON a.complex_id = ada.complex_id
)
SELECT
       borough_name                              AS borough,
       COUNT(DISTINCT complex_id)               AS total_stations,
       SUM(is_ada)                              AS ada_accessible_stations,
       ROUND(100 * SUM(is_ada) / COUNT(DISTINCT complex_id), 4) AS percent_ada_accessible
FROM stations_flagged
GROUP BY borough_name
ORDER BY percent_ada_accessible DESC;