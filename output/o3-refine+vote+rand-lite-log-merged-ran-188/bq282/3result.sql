-- Active council district with the greatest number of trips that start and end
-- inside the same district but at different stations
WITH active_stations AS (
  SELECT
    station_id,
    council_district
  FROM `bigquery-public-data.austin_bikeshare.bikeshare_stations`
  WHERE LOWER(status) = 'active'
    AND council_district IS NOT NULL
)

SELECT district
FROM (
  SELECT
    s.council_district AS district,
    COUNT(*) AS trip_count
  FROM `bigquery-public-data.austin_bikeshare.bikeshare_trips` AS t
  JOIN active_stations AS s
    ON t.start_station_id = s.station_id                      -- start station
  JOIN active_stations AS e
    ON t.end_station_id = CAST(e.station_id AS STRING)        -- end station
  WHERE s.council_district = e.council_district               -- same district
    AND CAST(t.start_station_id AS STRING) <> t.end_station_id -- different stations
  GROUP BY s.council_district
  ORDER BY trip_count DESC
  LIMIT 1
)