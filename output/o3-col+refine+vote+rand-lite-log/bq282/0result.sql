SELECT
  s.council_district AS highest_trip_council_district
FROM
  `bigquery-public-data.austin_bikeshare.bikeshare_trips` AS t
JOIN
  `bigquery-public-data.austin_bikeshare.bikeshare_stations` AS s
    ON t.start_station_id = s.station_id
   AND LOWER(s.status) = 'active'
JOIN
  `bigquery-public-data.austin_bikeshare.bikeshare_stations` AS e
    ON SAFE_CAST(t.end_station_id AS INT64) = e.station_id
   AND LOWER(e.status) = 'active'
WHERE
  SAFE_CAST(t.end_station_id AS INT64) IS NOT NULL
  AND s.council_district = e.council_district         -- same district
  AND t.start_station_id <> SAFE_CAST(t.end_station_id AS INT64)  -- different stations
GROUP BY
  s.council_district
ORDER BY
  COUNT(*) DESC
LIMIT 1;