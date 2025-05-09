WITH berkeley_stations AS (
  SELECT
    SAFE_CAST(s.station_id AS INT64) AS station_id_int
  FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info` AS s
  JOIN `bigquery-public-data.san_francisco_bikeshare.bikeshare_regions`        AS r
    ON s.region_id = r.region_id
  WHERE r.name = 'Berkeley'
),
trip_speeds AS (
  SELECT
    t.trip_id,
    ST_DISTANCE(t.start_station_geom, t.end_station_geom)           AS distance_m,
    t.duration_sec,
    ST_DISTANCE(t.start_station_geom, t.end_station_geom)
/ NULLIF(t.duration_sec,0)                                          AS speed_m_s
  FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips` AS t
  WHERE t.start_station_geom IS NOT NULL
    AND t.end_station_geom   IS NOT NULL
    AND ST_DISTANCE(t.start_station_geom, t.end_station_geom) > 1000        -- distance filter
    AND SAFE_CAST(t.start_station_id AS INT64) IN (SELECT station_id_int
                                                   FROM berkeley_stations)   -- Berkeley trips
)
SELECT ROUND(MAX(speed_m_s),1) AS highest_avg_speed_m_s
FROM trip_speeds;