SELECT
  ROUND(
    MAX(
      ST_DISTANCE(t.start_station_geom, t.end_station_geom) / t.duration_sec
    ),
    1
  ) AS highest_average_speed_m_s
FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips` AS t
JOIN `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info` AS s
  ON CAST(t.start_station_id AS STRING) = s.station_id
JOIN `bigquery-public-data.san_francisco_bikeshare.bikeshare_regions` AS r
  ON s.region_id = r.region_id
WHERE r.name = 'Berkeley'
  AND t.duration_sec > 0
  AND t.start_station_geom IS NOT NULL
  AND t.end_station_geom   IS NOT NULL
  AND ST_DISTANCE(t.start_station_geom, t.end_station_geom) > 1000;