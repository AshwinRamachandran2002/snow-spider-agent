-- Council district with the most trips that
--   • start & end in the same active district
--   • but use DIFFERENT stations
SELECT district
FROM (
  SELECT
    s_start.council_district AS district,
    COUNT(*)                 AS trips
  FROM `bigquery-public-data.austin_bikeshare.bikeshare_trips`     AS t
  JOIN `bigquery-public-data.austin_bikeshare.bikeshare_stations`  AS s_start
        ON t.start_station_id = s_start.station_id
  JOIN `bigquery-public-data.austin_bikeshare.bikeshare_stations`  AS s_end
        ON SAFE_CAST(t.end_station_id AS INT64) = s_end.station_id
  WHERE
        SAFE_CAST(t.end_station_id AS INT64) IS NOT NULL
    AND LOWER(s_start.status) = 'active'
    AND LOWER(s_end.status)   = 'active'
    AND s_start.council_district = s_end.council_district          -- same district
    AND t.start_station_id <> SAFE_CAST(t.end_station_id AS INT64) -- different stations
  GROUP BY district
  ORDER BY trips DESC
  LIMIT 1
);