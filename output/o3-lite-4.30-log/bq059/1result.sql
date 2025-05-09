SELECT
  ROUND(
    MAX(ST_DISTANCE(t.start_station_geom, t.end_station_geom) / t.duration_sec)
  , 1) AS highest_average_speed_m_s
FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips` AS t
JOIN `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info` AS s_start
  ON CAST(t.start_station_id AS STRING) = s_start.station_id
WHERE s_start.region_id = 14                    -- Berkeley start station
  AND ST_DISTANCE(t.start_station_geom, t.end_station_geom) > 1000
  AND t.duration_sec > 0;