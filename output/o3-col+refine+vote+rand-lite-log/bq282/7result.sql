-- Active council district with the highest count of trips that
-- start and end in the same district but at different stations
SELECT council_district
FROM (
  SELECT
    s_start.council_district,
    COUNT(*) AS trip_cnt,
    ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS rn
  FROM `bigquery-public-data.austin_bikeshare.bikeshare_trips`  AS t
  JOIN `bigquery-public-data.austin_bikeshare.bikeshare_stations` AS s_start
    ON t.start_station_id = s_start.station_id
  JOIN `bigquery-public-data.austin_bikeshare.bikeshare_stations` AS s_end
    ON SAFE_CAST(t.end_station_id AS INT64) = s_end.station_id
  WHERE
        s_start.status = 'active'
    AND s_end.status   = 'active'
    AND s_start.council_district = s_end.council_district
    AND t.start_station_id <> SAFE_CAST(t.end_station_id AS INT64)
  GROUP BY s_start.council_district
)
WHERE rn = 1;