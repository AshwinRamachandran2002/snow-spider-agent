WITH stations AS (
  SELECT
    station_id,
    borough_name AS borough,
    station_geom
  FROM `bigquery-public-data.new_york_subway.stations`
),

-- total number of stations in each borough
total AS (
  SELECT
    borough,
    COUNT(DISTINCT station_id) AS total_stations
  FROM stations
  GROUP BY borough
),

-- stations that have at least one ADA–compliant entrance that is an actual entry
ada_station_ids AS (
  SELECT DISTINCT
    s.station_id,
    s.borough
  FROM `bigquery-public-data.new_york_subway.station_entrances` AS e
  JOIN stations AS s
    ON ST_DWithin(e.station_geom, s.station_geom, 10)   -- match entrance to station (≈10 m)
  WHERE e.entry = TRUE
    AND e.ada_compliant = TRUE
),

ada_counts AS (
  SELECT
    borough,
    COUNT(DISTINCT station_id) AS ada_stations
  FROM ada_station_ids
  GROUP BY borough
)

SELECT
  t.borough,
  t.total_stations,
  COALESCE(a.ada_stations, 0) AS ada_stations,
  ROUND(COALESCE(a.ada_stations, 0) / t.total_stations * 100, 2) AS percentage_of_total
FROM total AS t
LEFT JOIN ada_counts AS a
USING (borough)
ORDER BY percentage_of_total DESC, borough;