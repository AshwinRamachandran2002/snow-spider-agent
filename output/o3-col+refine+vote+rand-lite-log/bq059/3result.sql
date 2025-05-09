-- highest average speed (m/s, 1-decimal) for Berkeley bike trips longer than 1 000 m
WITH berkeley_stations AS (
  SELECT DISTINCT CAST(station_id AS INT64) AS station_id
  FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info`
  WHERE region_id = 14
    AND SAFE_CAST(station_id AS INT64) IS NOT NULL
),
trip_metrics AS (
  SELECT
    ST_DISTANCE(
      ST_GEOGPOINT(start_station_longitude, start_station_latitude),
      ST_GEOGPOINT(end_station_longitude,   end_station_latitude)
    ) / duration_sec AS avg_speed_mps
  FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips`
  WHERE duration_sec > 0
    AND (
          start_station_id IN (SELECT station_id FROM berkeley_stations)
       OR end_station_id   IN (SELECT station_id FROM berkeley_stations)
        )
    AND ST_DISTANCE(
          ST_GEOGPOINT(start_station_longitude, start_station_latitude),
          ST_GEOGPOINT(end_station_longitude,   end_station_latitude)
        ) > 1000
)
SELECT ROUND(MAX(avg_speed_mps), 1) AS highest_avg_speed_mps
FROM trip_metrics;