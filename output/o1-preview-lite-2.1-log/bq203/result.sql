SELECT
  s.borough_name,
  ROUND(
    SAFE_DIVIDE(
      COUNT(DISTINCT IF(e.ada_compliant = TRUE, s.station_id, NULL)),
      COUNT(DISTINCT s.station_id)
    ) * 100, 4
  ) AS percentage_of_ada_stations
FROM
  `bigquery-public-data.new_york_subway.stations` AS s
LEFT JOIN
  `bigquery-public-data.new_york_subway.station_entrances` AS e
ON
  LOWER(s.station_name) = LOWER(e.station_name)
GROUP BY
  s.borough_name
ORDER BY
  s.borough_name;