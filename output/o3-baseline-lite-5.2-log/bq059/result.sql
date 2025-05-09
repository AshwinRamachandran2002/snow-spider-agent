WITH berkeley_trips AS (
  SELECT
    t.trip_id,
    t.duration_sec,
    ST_DISTANCE(t.start_station_geom, t.end_station_geom) AS distance_m,
    ST_DISTANCE(t.start_station_geom, t.end_station_geom) / t.duration_sec AS speed_m_per_s
  FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips` AS t
  JOIN `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info` AS si
    ON t.start_station_id = CAST(si.station_id AS INT64)
  WHERE
    si.region_id = 14                     -- Berkeley stations
    AND t.duration_sec > 0
    AND t.start_station_geom IS NOT NULL
    AND t.end_station_geom  IS NOT NULL
)
SELECT
  ROUND(MAX(speed_m_per_s), 1) AS highest_avg_speed_m_per_s
FROM berkeley_trips
WHERE distance_m > 1000;