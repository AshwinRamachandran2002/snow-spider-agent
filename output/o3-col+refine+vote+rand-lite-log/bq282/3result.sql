-- Active council district with the most trips that start & end within the same
-- district but at different (active) bike-share stations
SELECT district
FROM (
  SELECT
    s_start.council_district AS district,
    COUNT(*)                AS trip_count
  FROM `bigquery-public-data.austin_bikeshare.bikeshare_trips`    AS t
  JOIN `bigquery-public-data.austin_bikeshare.bikeshare_stations` AS s_start
    ON t.start_station_id = s_start.station_id
  JOIN `bigquery-public-data.austin_bikeshare.bikeshare_stations` AS s_end
    ON SAFE_CAST(t.end_station_id AS INT64) = s_end.station_id
  WHERE SAFE_CAST(t.end_station_id AS INT64) IS NOT NULL      -- ignore bad IDs
    AND s_start.status = 'active'                             -- start station active
    AND s_end.status   = 'active'                             -- end   station active
    AND s_start.council_district = s_end.council_district     -- same district
    AND t.start_station_id <> SAFE_CAST(t.end_station_id AS INT64)  -- diff stations
  GROUP BY district
  ORDER BY trip_count DESC
  LIMIT 1
);