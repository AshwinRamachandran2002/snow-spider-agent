-- Highest average straight‑line speed (m/s) for Berkeley bike‑share trips >1 km
WITH berkeley_stations AS (
  SELECT CAST(station_id AS INT64) AS station_id
  FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info`
  WHERE region_id = 14                           -- Berkeley
),
trip_speeds AS (
  SELECT
    ST_DISTANCE(t.start_station_geom, t.end_station_geom)          AS meters,
    t.duration_sec,
    ST_DISTANCE(t.start_station_geom, t.end_station_geom)
/ t.duration_sec                                                   AS speed_mps
  FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips` AS t
  LEFT JOIN berkeley_stations b_start ON t.start_station_id = b_start.station_id
  LEFT JOIN berkeley_stations b_end   ON t.end_station_id   = b_end.station_id
  WHERE (b_start.station_id IS NOT NULL OR b_end.station_id IS NOT NULL)  -- origin OR destination in Berkeley
    AND t.duration_sec > 0
    AND ST_DISTANCE(t.start_station_geom, t.end_station_geom) > 1000      -- >1 km
)

SELECT ROUND(MAX(speed_mps), 1) AS highest_avg_speed_mps
FROM trip_speeds;