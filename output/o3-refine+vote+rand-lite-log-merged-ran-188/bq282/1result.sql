WITH stations AS (
  SELECT
    station_id,
    council_district
  FROM `bigquery-public-data.austin_bikeshare.bikeshare_stations`
  WHERE council_district IS NOT NULL
),
trip_pairs AS (
  SELECT
    SAFE_CAST(start_station_id AS INT64)   AS start_id,
    SAFE_CAST(end_station_id   AS INT64)   AS end_id
  FROM `bigquery-public-data.austin_bikeshare.bikeshare_trips`
)
SELECT
  s_start.council_district AS council_district_with_most_internal_trips
FROM trip_pairs tp
JOIN stations s_start ON tp.start_id = s_start.station_id
JOIN stations s_end   ON tp.end_id   = s_end.station_id
WHERE
  s_start.council_district = s_end.council_district         -- same district
  AND tp.start_id <> tp.end_id                               -- different stations
GROUP BY s_start.council_district
ORDER BY COUNT(*) DESC
LIMIT 1;