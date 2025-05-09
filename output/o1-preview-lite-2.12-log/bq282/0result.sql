SELECT s.council_district AS Council_District
FROM `bigquery-public-data.austin_bikeshare.bikeshare_trips` t
JOIN `bigquery-public-data.austin_bikeshare.bikeshare_stations` s
  ON SAFE_CAST(t.start_station_id AS INT64) = s.station_id
JOIN `bigquery-public-data.austin_bikeshare.bikeshare_stations` e
  ON SAFE_CAST(t.end_station_id AS INT64) = e.station_id
WHERE SAFE_CAST(t.start_station_id AS INT64) != SAFE_CAST(t.end_station_id AS INT64)
  AND s.council_district = e.council_district
  AND s.council_district IS NOT NULL
GROUP BY s.council_district
ORDER BY COUNT(*) DESC
LIMIT 1;