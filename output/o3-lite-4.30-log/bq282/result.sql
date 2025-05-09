WITH active_stations AS (
  SELECT
    station_id,
    council_district
  FROM `bigquery-public-data.austin_bikeshare.bikeshare_stations`
  WHERE status = 'active'
),
same_district_trips AS (
  SELECT
    s.council_district AS district
  FROM `bigquery-public-data.austin_bikeshare.bikeshare_trips` AS t
  JOIN active_stations AS s
    ON t.start_station_id = s.station_id
  JOIN active_stations AS e
    ON SAFE_CAST(t.end_station_id AS INT64) = e.station_id
  WHERE s.council_district = e.council_district
    AND t.start_station_id <> SAFE_CAST(t.end_station_id AS INT64)
)
SELECT
  district AS council_district
FROM (
  SELECT
    district,
    COUNT(*) AS trip_count
  FROM same_district_trips
  GROUP BY district
  ORDER BY trip_count DESC
  LIMIT 1
);