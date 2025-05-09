-- Numeric council district with the most bike trips that start and end
-- in the same (active) district but at DIFFERENT stations
SELECT
  s.council_district AS district_with_most_trips
FROM `bigquery-public-data.austin_bikeshare.bikeshare_trips`    AS t
JOIN `bigquery-public-data.austin_bikeshare.bikeshare_stations` AS s
  ON t.start_station_id = s.station_id
JOIN `bigquery-public-data.austin_bikeshare.bikeshare_stations` AS e
  ON SAFE_CAST(t.end_station_id AS INT64) = e.station_id
WHERE s.status = 'active'                       -- start station active
  AND e.status = 'active'                       -- end station active
  AND SAFE_CAST(t.end_station_id AS INT64) IS NOT NULL
  AND s.council_district = e.council_district   -- same district
  AND t.start_station_id <> SAFE_CAST(t.end_station_id AS INT64) -- different stations
GROUP BY district_with_most_trips
ORDER BY COUNT(*) DESC
LIMIT 1;