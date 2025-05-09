--  Subways stations with ADA‑compliant, usable entrances,
--  share per borough (highest → lowest)

WITH stations AS (
    SELECT
      station_id,
      station_name,
      borough_name
    FROM
      `bigquery-public-data.new_york_subway.stations`
),

ada_station_names AS (
    -- station names that have at least one entrance
    -- which is both an entry point and ADA‑compliant
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
      s.borough_name,
      IF(a.station_name IS NOT NULL, 1, 0) AS has_ada_entry
    FROM
      stations AS s
      LEFT JOIN ada_station_names AS a
      ON s.station_name = a.station_name
)

SELECT
  borough_name                         AS borough,
  COUNT(DISTINCT station_id)           AS total_stations,
  SUM(has_ada_entry)                   AS ada_stations,
  ROUND(100 * SUM(has_ada_entry) / COUNT(DISTINCT station_id), 4)
                                        AS ada_percentage
FROM
  station_flags
GROUP BY
  borough
ORDER BY
  ada_percentage DESC,
  borough;