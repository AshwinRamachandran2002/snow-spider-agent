-- Council district with the most trips that start & end in the same active district
-- but at different active stations
SELECT district
FROM (
  SELECT
    s_start.council_district AS district,
    COUNT(*)                AS trip_cnt
  FROM `bigquery-public-data.austin_bikeshare.bikeshare_trips`    AS t
  JOIN `bigquery-public-data.austin_bikeshare.bikeshare_stations` AS s_start
    ON t.start_station_id = s_start.station_id
  JOIN `bigquery-public-data.austin_bikeshare.bikeshare_stations` AS s_end
    ON SAFE_CAST(t.end_station_id AS INT64) = s_end.station_id        -- handle non-numeric IDs
  WHERE LOWER(s_start.status) = 'active'                              -- both stations active
    AND LOWER(s_end.status)   = 'active'
    AND s_start.council_district = s_end.council_district             -- same district
    AND s_start.station_id      <> s_end.station_id                   -- different stations
  GROUP BY district
  ORDER BY trip_cnt DESC
  LIMIT 1
);