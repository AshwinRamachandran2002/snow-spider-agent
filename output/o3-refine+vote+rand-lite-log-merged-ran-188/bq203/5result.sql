WITH ada_station_names AS (
  -- Stations that have at least one entrance that is BOTH an actual entry
  -- and ADA–compliant
  SELECT DISTINCT
         station_name
  FROM `bigquery-public-data.new_york_subway.station_entrances`
  WHERE entry = TRUE
    AND ada_compliant = TRUE
),
stations_with_borough AS (
  -- Universe of subway stations with their boroughs
  SELECT DISTINCT
         station_id,
         station_name,
         borough_name
  FROM `bigquery-public-data.new_york_subway.stations`
),
ada_stations_by_borough AS (
  -- ADA‑accessible stations mapped to boroughs
  SELECT DISTINCT
         s.station_id,
         s.borough_name
  FROM stations_with_borough AS s
  JOIN ada_station_names  AS a
    ON s.station_name = a.station_name
)
SELECT
  s.borough_name                                   AS borough,
  COUNT(DISTINCT s.station_id)                     AS total_stations,
  COUNT(DISTINCT a.station_id)                     AS ada_entry_stations,
  ROUND(COUNT(DISTINCT a.station_id)
        / COUNT(DISTINCT s.station_id) * 100, 4)   AS ada_percentage
FROM stations_with_borough AS s
LEFT JOIN ada_stations_by_borough AS a
       ON s.station_id = a.station_id
GROUP BY borough
ORDER BY ada_percentage DESC;