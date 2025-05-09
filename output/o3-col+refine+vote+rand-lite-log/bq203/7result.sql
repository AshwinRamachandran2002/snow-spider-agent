-- Borough-level subway station counts and ADA–accessible coverage
WITH
-- 1.  Total stations per borough
total AS (
  SELECT
    borough_name,
    COUNT(DISTINCT station_id) AS total_stations
  FROM `bigquery-public-data.new_york_subway.stations`
  GROUP BY borough_name
),

-- 2.  Stations that have at least one entrance that is BOTH
--     an actual entry and ADA-compliant
ada_station_names AS (
  SELECT DISTINCT
    LOWER(station_name) AS station_name_lower
  FROM `bigquery-public-data.new_york_subway.station_entrances`
  WHERE entry = TRUE
    AND ada_compliant = TRUE
),

-- 3.  Map those ADA station names to station_ids & boroughs
ada AS (
  SELECT
    s.borough_name,
    COUNT(DISTINCT s.station_id) AS ada_station_count
  FROM `bigquery-public-data.new_york_subway.stations` AS s
  JOIN ada_station_names AS a
    ON LOWER(s.station_name) = a.station_name_lower
  GROUP BY s.borough_name
)

-- 4.  Combine & calculate percentage
SELECT
  t.borough_name                                   AS borough,
  t.total_stations,
  IFNULL(a.ada_station_count, 0)                   AS ada_station_count,
  ROUND(100 * IFNULL(a.ada_station_count, 0)
            / t.total_stations, 2)                 AS ada_percentage
FROM total AS t
LEFT JOIN ada AS a
  USING (borough_name)
ORDER BY ada_percentage DESC;