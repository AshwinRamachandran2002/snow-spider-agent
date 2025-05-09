-- ADA-accessible vs. total subway stations by NYC borough
WITH

-- 1.  Total number of unique stations in each borough
total AS (
  SELECT
    borough_name,
    COUNT(DISTINCT station_name) AS total_stations
  FROM
    `bigquery-public-data.new_york_subway.stations`
  GROUP BY
    borough_name
),

-- 2.  Stations that have ≥1 entrance which is BOTH usable for entry
--     and ADA-compliant
ada_stations AS (
  SELECT DISTINCT
    station_name
  FROM
    `bigquery-public-data.new_york_subway.station_entrances`
  WHERE
    entry = TRUE
    AND ada_compliant = TRUE
),

-- 3.  Count of those ADA-accessible stations per borough
ada AS (
  SELECT
    s.borough_name,
    COUNT(DISTINCT s.station_name) AS ada_stations
  FROM
    `bigquery-public-data.new_york_subway.stations`  AS s
  JOIN
    ada_stations                                      AS a
  USING
    (station_name)
  GROUP BY
    s.borough_name
)

-- 4.  Combine and calculate percentage
SELECT
  t.borough_name                           AS borough,
  t.total_stations,
  COALESCE(a.ada_stations, 0)              AS ada_stations,
  ROUND(COALESCE(a.ada_stations, 0)
/ t.total_stations * 100, 2)               AS ada_percentage
FROM
  total AS t
LEFT JOIN
  ada   AS a
USING
  (borough_name)
ORDER BY
  ada_percentage DESC;