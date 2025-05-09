SELECT
  ROUND(
    MAX(
      ST_DISTANCE(s_start.station_geom, s_end.station_geom) / t.duration_sec
    ),
    1
  ) AS highest_average_speed_mps
FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips` AS t
JOIN `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info` AS s_start
  ON t.start_station_id = CAST(s_start.station_id AS INT64)
JOIN `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info` AS s_end
  ON t.end_station_id = CAST(s_end.station_id AS INT64)
WHERE s_start.region_id = 14                            -- trips that start in Berkeley
  AND ST_DISTANCE(s_start.station_geom, s_end.station_geom) > 1000   -- distance > 1 000 m
  AND t.duration_sec > 0;                               -- guard against divide-by-zero