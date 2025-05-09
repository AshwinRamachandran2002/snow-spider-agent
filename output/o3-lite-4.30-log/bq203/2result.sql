WITH ada_stations AS (
  -- Stations that have at least one entrance which is BOTH an entry and ADA‑compliant
  SELECT DISTINCT
         LOWER(station_name) AS station_name_norm
  FROM `bigquery-public-data.new_york_subway.station_entrances`
  WHERE entry = TRUE
    AND ada_compliant = TRUE
)

SELECT
  s.borough_name                                             AS borough,
  COUNT(DISTINCT s.station_id)                               AS total_stations,
  COUNT(DISTINCT IF(a.station_name_norm IS NOT NULL,
                    s.station_id,
                    NULL))                                   AS ada_compliant_stations,
  ROUND(
        COUNT(DISTINCT IF(a.station_name_norm IS NOT NULL, s.station_id, NULL))
        / COUNT(DISTINCT s.station_id) * 100,                -- percentage
        4)                                                   AS ada_percentage
FROM `bigquery-public-data.new_york_subway.stations` AS s
LEFT JOIN ada_stations AS a
       ON LOWER(s.station_name) = a.station_name_norm
GROUP BY borough
ORDER BY ada_percentage DESC, borough;