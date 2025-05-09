WITH prepared_trips AS (
  SELECT
    trip_id,
    start_station_id,
    SAFE_CAST(end_station_id AS INT64) AS end_station_id
  FROM `bigquery-public-data.austin_bikeshare.bikeshare_trips`
  WHERE start_station_id IS NOT NULL
)

SELECT
  s_start.council_district
FROM prepared_trips t
JOIN `bigquery-public-data.austin_bikeshare.bikeshare_stations` AS s_start
  ON t.start_station_id = s_start.station_id
JOIN `bigquery-public-data.austin_bikeshare.bikeshare_stations` AS s_end
  ON t.end_station_id = s_end.station_id
WHERE
  t.end_station_id IS NOT NULL
  AND t.start_station_id != t.end_station_id                                   -- different stations
  AND s_start.council_district = s_end.council_district                        -- same district
  AND s_start.status = 'active'                                                -- both stations active
  AND s_end.status   = 'active'
GROUP BY
  s_start.council_district
ORDER BY
  COUNT(*) DESC
LIMIT 1;