SELECT
  s_start.council_district AS Council_District
FROM `bigquery-public-data.austin_bikeshare.bikeshare_trips` AS t
JOIN `bigquery-public-data.austin_bikeshare.bikeshare_stations` AS s_start
  ON t.start_station_id = s_start.station_id
  AND s_start.status = 'active'
JOIN `bigquery-public-data.austin_bikeshare.bikeshare_stations` AS s_end
  ON SAFE_CAST(t.end_station_id AS INT64) = s_end.station_id
  AND s_end.status = 'active'
WHERE s_start.council_district = s_end.council_district
  AND SAFE_CAST(t.end_station_id AS INT64) IS NOT NULL
  AND t.start_station_id != SAFE_CAST(t.end_station_id AS INT64)
GROUP BY Council_District
ORDER BY COUNT(*) DESC
LIMIT 1;