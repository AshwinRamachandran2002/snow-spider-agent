SELECT district
FROM (
  SELECT
    s.council_district AS district,
    COUNT(*) AS trip_count
  FROM `bigquery-public-data.austin_bikeshare.bikeshare_trips` AS t
  JOIN (
    SELECT station_id, council_district
    FROM `bigquery-public-data.austin_bikeshare.bikeshare_stations`
    WHERE LOWER(status) = 'active'
      AND council_district IS NOT NULL
  ) AS s
    ON t.start_station_id = s.station_id
  JOIN (
    SELECT station_id, council_district
    FROM `bigquery-public-data.austin_bikeshare.bikeshare_stations`
    WHERE LOWER(status) = 'active'
      AND council_district IS NOT NULL
  ) AS e
    ON SAFE_CAST(t.end_station_id AS INT64) = e.station_id
  WHERE
    s.council_district = e.council_district       -- same district
    AND t.start_station_id != SAFE_CAST(t.end_station_id AS INT64) -- different stations
  GROUP BY district
)
ORDER BY trip_count DESC, district          -- pick the district with the most such trips
LIMIT 1;