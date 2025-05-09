WITH ada_accessible_stations AS (
  -- stations that have at least one entrance which is BOTH an entry and ADA‑compliant
  SELECT DISTINCT
         LOWER(station_name) AS station_name_norm
  FROM `bigquery-public-data.new_york_subway.station_entrances`
  WHERE entry = TRUE
    AND ada_compliant = TRUE
),

borough_counts AS (
  SELECT
    s.borough_name                              AS borough,
    COUNT(DISTINCT s.station_id)                AS total_stations,
    COUNT(DISTINCT CASE
                     WHEN a.station_name_norm IS NOT NULL
                     THEN s.station_id
                   END)                         AS ada_stations
  FROM `bigquery-public-data.new_york_subway.stations` AS s
  LEFT JOIN ada_accessible_stations AS a
         ON LOWER(s.station_name) = a.station_name_norm
  GROUP BY borough
)

SELECT
  borough,
  total_stations,
  ada_stations,
  ROUND(ada_stations * 100.0 / total_stations, 4) AS percentage_ada_stations
FROM borough_counts
ORDER BY percentage_ada_stations DESC, borough;