WITH active_stations AS (
  SELECT
    station_id,
    council_district
  FROM
    `bigquery-public-data.austin_bikeshare.bikeshare_stations`
  WHERE
    LOWER(status) = 'active'
    AND council_district IS NOT NULL
),
trips AS (
  SELECT
    start_station_id,
    SAFE_CAST(end_station_id AS INT64) AS end_station_id
  FROM
    `bigquery-public-data.austin_bikeshare.bikeshare_trips`
  WHERE
    start_station_id IS NOT NULL
    AND SAFE_CAST(end_station_id AS INT64) IS NOT NULL
    AND start_station_id <> SAFE_CAST(end_station_id AS INT64)      -- different stations
),
trips_same_district AS (
  SELECT
    s_start.council_district AS district
  FROM
    trips t
    JOIN active_stations s_start ON t.start_station_id = s_start.station_id
    JOIN active_stations s_end   ON t.end_station_id   = s_end.station_id
  WHERE
    s_start.council_district = s_end.council_district                -- same district
)
SELECT district
FROM (
  SELECT
    district,
    COUNT(*) AS trip_cnt,
    ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS rn
  FROM
    trips_same_district
  GROUP BY
    district
)
WHERE rn = 1;