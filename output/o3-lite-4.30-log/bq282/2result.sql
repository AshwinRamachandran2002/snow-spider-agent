SELECT
  s1.council_district AS council_district
FROM `bigquery-public-data.austin_bikeshare.bikeshare_trips` AS t
JOIN `bigquery-public-data.austin_bikeshare.bikeshare_stations` AS s1
  ON t.start_station_id = s1.station_id
JOIN `bigquery-public-data.austin_bikeshare.bikeshare_stations` AS s2
  ON t.end_station_id = CAST(s2.station_id AS STRING)
WHERE
  s1.status = 'active'
  AND s2.status = 'active'
  AND s1.council_district = s2.council_district
  AND CAST(t.start_station_id AS STRING) <> t.end_station_id
  AND s1.council_district IS NOT NULL
GROUP BY
  council_district
ORDER BY
  COUNT(*) DESC
LIMIT 1;