WITH stations AS (
  SELECT
    station_id,
    station_name,
    borough_name
  FROM
    `bigquery-public-data.new_york_subway.stations`
),
ada_station_names AS (
  SELECT DISTINCT
    station_name
  FROM
    `bigquery-public-data.new_york_subway.station_entrances`
  WHERE
    entry = TRUE
    AND ada_compliant = TRUE
),
station_flags AS (
  SELECT
    s.station_id,
    s.borough_name AS borough,
    IF(a.station_name IS NOT NULL, 1, 0) AS is_ada
  FROM
    stations AS s
  LEFT JOIN
    ada_station_names AS a
  USING
    (station_name)
)
SELECT
  borough,
  COUNT(*) AS total_stations,
  SUM(is_ada) AS ada_stations,
  ROUND(SAFE_DIVIDE(SUM(is_ada) * 100.0, COUNT(*)), 4) AS ada_percentage
FROM
  station_flags
GROUP BY
  borough
ORDER BY
  ada_percentage DESC;