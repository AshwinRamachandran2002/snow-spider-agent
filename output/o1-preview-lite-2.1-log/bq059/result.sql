SELECT
  ROUND(MAX(ST_DISTANCE(t.start_station_geom, t.end_station_geom) / t.duration_sec), 1) AS Highest_average_speed_meters_per_second
FROM
  `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips` AS t
JOIN
  `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info` AS s_start
  ON t.start_station_id = CAST(s_start.station_id AS INT64)
JOIN
  `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info` AS s_end
  ON t.end_station_id = CAST(s_end.station_id AS INT64)
WHERE
  t.duration_sec > 0
  AND ST_DISTANCE(t.start_station_geom, t.end_station_geom) > 1000
  AND (LOWER(s_start.name) LIKE '%berkeley%' OR LOWER(s_end.name) LIKE '%berkeley%')