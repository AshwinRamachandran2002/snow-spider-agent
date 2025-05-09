WITH active_stations AS (
  SELECT
    station_id,
    council_district
  FROM `bigquery-public-data.austin_bikeshare.bikeshare_stations`
  WHERE LOWER(status) = 'active'
    AND council_district IS NOT NULL
),
same_district_trips AS (
  SELECT
    s_start.council_district AS district
  FROM `bigquery-public-data.austin_bikeshare.bikeshare_trips` t
  JOIN active_stations AS s_start
    ON t.start_station_id = s_start.station_id
  JOIN active_stations AS s_end
    ON SAFE_CAST(t.end_station_id AS INT64) = s_end.station_id
  WHERE t.start_station_id <> SAFE_CAST(t.end_station_id AS INT64)         -- different stations
    AND s_start.council_district = s_end.council_district                  -- same council district
)
SELECT district
FROM same_district_trips
GROUP BY district
ORDER BY COUNT(*) DESC
LIMIT 1;