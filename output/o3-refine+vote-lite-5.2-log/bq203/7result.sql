-- 1)  Every subway station geometry is stored once in `stations.station_geom`.
-- 2)  Each entrance row repeats that same geometry in `station_entrances.station_geom`.
--     We can therefore match a station to all of its entrances with
--     ST_EQUALS(station_geom , station_geom).
-- 3)  Count, per borough, how many distinct stations have at least one
--     ADA–compliant entrance that is also an actual entry (`entry = TRUE`).

WITH ada_station_per_borough AS (
    SELECT DISTINCT
           s.station_id,
           s.borough_name
    FROM `bigquery-public-data.new_york_subway.stations`          AS s
    JOIN `bigquery-public-data.new_york_subway.station_entrances` AS e
      ON ST_EQUALS(s.station_geom, e.station_geom)
    WHERE e.entry = TRUE
      AND e.ada_compliant = TRUE
),
borough_totals AS (
    SELECT
        borough_name,
        COUNT(DISTINCT station_id) AS total_stations
    FROM `bigquery-public-data.new_york_subway.stations`
    GROUP BY borough_name
),
borough_ada AS (
    SELECT
        borough_name,
        COUNT(DISTINCT station_id) AS ada_entry_stations
    FROM ada_station_per_borough
    GROUP BY borough_name
)

SELECT
    t.borough_name            AS borough,
    t.total_stations,
    COALESCE(a.ada_entry_stations, 0) AS ada_entry_stations,
    ROUND( COALESCE(a.ada_entry_stations, 0) * 100.0 / t.total_stations , 4)
        AS percentage_ada_entry_stations
FROM borough_totals t
LEFT JOIN borough_ada a
  ON t.borough_name = a.borough_name
ORDER BY percentage_ada_entry_stations DESC,
         borough;