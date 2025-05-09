SELECT
  s.borough_name AS borough,
  COUNT(DISTINCT s.station_id) AS total_stations,
  COUNT(DISTINCT IF(e.entry AND e.ada_compliant, s.station_id, NULL)) AS ada_compliant_stations,
  ROUND(
    100 * SAFE_DIVIDE(
      COUNT(DISTINCT IF(e.entry AND e.ada_compliant, s.station_id, NULL)),
      COUNT(DISTINCT s.station_id)
    ), 4
  ) AS ada_percentage
FROM `bigquery-public-data.new_york_subway.stations` AS s
LEFT JOIN `bigquery-public-data.new_york_subway.station_entrances` AS e
  ON LOWER(s.station_name) = LOWER(e.station_name)
GROUP BY s.borough_name
ORDER BY ada_percentage DESC;