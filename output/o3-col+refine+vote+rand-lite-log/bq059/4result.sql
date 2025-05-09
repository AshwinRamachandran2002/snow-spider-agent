-- Highest average speed (m/s, rounded to 1 decimal) for Berkeley-only trips
-- whose start-to-end straight-line distance exceeds 1000 m
WITH berkeley_trips AS (
  SELECT
    ST_DISTANCE(s1.station_geom, s2.station_geom) / t.duration_sec AS speed_m_s
  FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips`        AS t
  JOIN `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info` AS s1
    ON CAST(s1.station_id AS INT64) = t.start_station_id
  JOIN `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info` AS s2
    ON CAST(s2.station_id AS INT64) = t.end_station_id
  WHERE s1.region_id = 14        -- Berkeley stations
    AND s2.region_id = 14        -- Berkeley stations
    AND ST_DISTANCE(s1.station_geom, s2.station_geom) > 1000
)

SELECT ROUND(MAX(speed_m_s), 1) AS highest_speed_m_s
FROM   berkeley_trips;