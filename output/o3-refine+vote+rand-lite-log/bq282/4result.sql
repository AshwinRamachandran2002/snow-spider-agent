SELECT council_district
FROM (
  SELECT
    s_start.council_district AS council_district,
    COUNT(*) AS trip_count
  FROM `bigquery-public-data.austin_bikeshare.bikeshare_trips` AS t
  JOIN `bigquery-public-data.austin_bikeshare.bikeshare_stations` AS s_start
    ON t.start_station_id = s_start.station_id
  JOIN `bigquery-public-data.austin_bikeshare.bikeshare_stations` AS s_end
    ON SAFE_CAST(t.end_station_id AS INT64) = s_end.station_id
  WHERE
    t.start_station_id != SAFE_CAST(t.end_station_id AS INT64)
    AND s_start.council_district IS NOT NULL
    AND s_start.council_district = s_end.council_district
  GROUP BY
    s_start.council_district
  ORDER BY
    trip_count DESC,
    council_district
  LIMIT 1
);