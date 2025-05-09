-- Stations with at least one entrance that is both an actual entry and ADA-compliant
WITH ada_stations AS (
  SELECT DISTINCT LOWER(station_name) AS station_name_lc
  FROM `bigquery-public-data.new_york_subway.station_entrances`
  WHERE entry = TRUE
    AND ada_compliant = TRUE
)

-- Totals, ADA counts, and percentages per borough
SELECT
  s.borough_name                                         AS borough,
  COUNT(DISTINCT s.station_id)                           AS total_stations,
  COUNT(DISTINCT CASE WHEN a.station_name_lc IS NOT NULL
                      THEN s.station_id END)             AS ada_entry_stations,
  ROUND(
    100 * COUNT(DISTINCT CASE WHEN a.station_name_lc IS NOT NULL
                              THEN s.station_id END)
        / COUNT(DISTINCT s.station_id)
  , 2)                                                   AS pct_of_stations_with_ada_entry
FROM `bigquery-public-data.new_york_subway.stations` AS s
LEFT JOIN ada_stations AS a
  ON LOWER(s.station_name) = a.station_name_lc
GROUP BY borough
ORDER BY pct_of_stations_with_ada_entry DESC;