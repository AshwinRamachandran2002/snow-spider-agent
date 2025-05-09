WITH stations AS (
  SELECT
    station_id,
    station_name,
    borough_name
  FROM `bigquery-public-data.new_york_subway.stations`
),
/* stations that have at least one entrance marked as an actual entry AND ADA‑compliant */
ada_station_ids AS (
  SELECT DISTINCT
    s.station_id
  FROM `bigquery-public-data.new_york_subway.station_entrances` e
  JOIN stations s
    ON e.station_name = s.station_name
  WHERE e.entry = TRUE
    AND e.ada_compliant = TRUE
),
/* borough‑level roll‑up */
borough_stats AS (
  SELECT
    s.borough_name                                   AS borough,
    COUNT(*)                                         AS total_stations,
    SUM(CASE WHEN s.station_id IN (SELECT station_id FROM ada_station_ids)
             THEN 1 ELSE 0 END)                      AS ada_accessible_stations
  FROM stations s
  GROUP BY s.borough_name
)
SELECT
  borough,
  total_stations,
  ada_accessible_stations,
  ROUND(SAFE_DIVIDE(ada_accessible_stations, total_stations) * 100, 2) AS ada_percentage
FROM borough_stats
ORDER BY ada_percentage DESC, borough;