WITH total AS (
  SELECT
    borough_name,
    COUNT(DISTINCT station_id) AS total_stations
  FROM `bigquery-public-data.new_york_subway.stations`
  GROUP BY borough_name
),
ada AS (
  SELECT
    s.borough_name,
    COUNT(DISTINCT s.station_id) AS ada_compliant_stations
  FROM `bigquery-public-data.new_york_subway.stations` AS s
  JOIN `bigquery-public-data.new_york_subway.station_entrances` AS e
    ON s.station_name = e.station_name
  WHERE e.entry = TRUE
    AND e.ada_compliant = TRUE
  GROUP BY s.borough_name
)
SELECT
  t.borough_name                         AS borough,
  t.total_stations,
  COALESCE(a.ada_compliant_stations, 0)  AS ada_compliant_stations,
  ROUND(
    COALESCE(a.ada_compliant_stations, 0) * 100.0 / t.total_stations,
    4
  )                                      AS ada_percentage
FROM total AS t
LEFT JOIN ada AS a
  USING (borough_name)
ORDER BY ada_percentage DESC, borough;