SELECT
  ROUND(MAX(ST_DISTANCE(t.start_station_geom, t.end_station_geom) / t.duration_sec), 1) 
    AS highest_avg_speed_mps
FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips` AS t
JOIN `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info` AS s_start
  ON CAST(t.start_station_id AS STRING) = s_start.station_id
JOIN `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info` AS s_end
  ON CAST(t.end_station_id AS STRING)   = s_end.station_id
WHERE (s_start.region_id = 14 OR s_end.region_id = 14)        -- trips that start or end in Berkeley
  AND ST_DISTANCE(t.start_station_geom, t.end_station_geom) > 1000;  -- only trips > 1 km