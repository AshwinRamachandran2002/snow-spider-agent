WITH berkeley_trips AS (
  SELECT
    t.trip_id,
    t.duration_sec,
    -- distance between the start and end points in meters
    ST_DISTANCE(
      ST_GEOGPOINT(t.start_station_longitude, t.start_station_latitude),
      ST_GEOGPOINT(t.end_station_longitude, t.end_station_latitude)
    ) AS distance_m
  FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips` AS t
  JOIN `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info` AS s
        ON CAST(t.start_station_id AS STRING) = s.station_id
  WHERE s.region_id = 14          -- Berkeley
    AND t.start_station_latitude  IS NOT NULL
    AND t.start_station_longitude IS NOT NULL
    AND t.end_station_latitude    IS NOT NULL
    AND t.end_station_longitude   IS NOT NULL
    AND t.duration_sec > 0
)
SELECT
  ROUND(MAX(distance_m / duration_sec), 1) AS highest_avg_speed_mps
FROM berkeley_trips
WHERE distance_m > 1000;