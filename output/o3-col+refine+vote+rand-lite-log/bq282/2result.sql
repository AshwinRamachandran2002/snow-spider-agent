SELECT
  start_meta.council_district AS council_district_with_max_trips
FROM `bigquery-public-data.austin_bikeshare.bikeshare_trips` AS t
JOIN `bigquery-public-data.austin_bikeshare.bikeshare_stations` AS start_meta
  ON t.start_station_id = start_meta.station_id
JOIN `bigquery-public-data.austin_bikeshare.bikeshare_stations` AS end_meta
  ON SAFE_CAST(t.end_station_id AS INT64) = end_meta.station_id
WHERE LOWER(start_meta.status) = 'active'
  AND LOWER(end_meta.status)   = 'active'
  AND t.start_station_id IS NOT NULL
  AND SAFE_CAST(t.end_station_id AS INT64) IS NOT NULL
  AND t.start_station_id <> SAFE_CAST(t.end_station_id AS INT64)       -- different stations
  AND start_meta.council_district = end_meta.council_district          -- same district
GROUP BY council_district_with_max_trips
ORDER BY COUNT(*) DESC
LIMIT 1;