SELECT
  s1.council_district
FROM `bigquery-public-data.austin_bikeshare.bikeshare_trips`   AS t
JOIN `bigquery-public-data.austin_bikeshare.bikeshare_stations` AS s1
  ON s1.station_id = t.start_station_id
JOIN `bigquery-public-data.austin_bikeshare.bikeshare_stations` AS s2
  ON s2.station_id = SAFE_CAST(t.end_station_id AS INT64)
WHERE s1.council_district = s2.council_district          -- start & end in same district
  AND t.start_station_id <> SAFE_CAST(t.end_station_id AS INT64)  -- but not same station
  AND s1.council_district IS NOT NULL                    -- active districts only
GROUP BY s1.council_district
ORDER BY COUNT(*) DESC
LIMIT 1;