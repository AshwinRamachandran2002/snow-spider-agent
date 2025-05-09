WITH active_stations AS (
  SELECT
    station_id,
    council_district
  FROM `bigquery-public-data.austin_bikeshare.bikeshare_stations`
  WHERE LOWER(status) = 'active'
    AND council_district IS NOT NULL
),
filtered_trips AS (
  SELECT
    start_station_id,
    SAFE_CAST(end_station_id AS INT64) AS end_station_id
  FROM `bigquery-public-data.austin_bikeshare.bikeshare_trips`
  WHERE SAFE_CAST(end_station_id AS INT64) IS NOT NULL            -- keep only numeric end‑station IDs
)

SELECT district
FROM (
  SELECT
    s_start.council_district AS district,
    COUNT(*) AS trip_count
  FROM filtered_trips AS t
  JOIN active_stations AS s_start
    ON t.start_station_id = s_start.station_id
  JOIN active_stations AS s_end
    ON t.end_station_id = s_end.station_id
  WHERE s_start.council_district = s_end.council_district          -- same council district
    AND t.start_station_id <> t.end_station_id                     -- different stations
  GROUP BY s_start.council_district
  ORDER BY trip_count DESC
  LIMIT 1
)