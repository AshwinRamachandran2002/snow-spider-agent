-- Highest average speed (m/s) for Berkeley bike trips whose
-- trip distance is greater than 1 000 m
WITH berkeley_stations AS (
  SELECT CAST(station_id AS INT64) AS station_id
  FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info`
  WHERE region_id = 14                                       -- Berkeley
),
trips_with_speed AS (
  SELECT
    t.trip_id,
    t.duration_sec,
    ST_DISTANCE(
      ST_GEOGPOINT(t.start_station_longitude, t.start_station_latitude),
      ST_GEOGPOINT(t.end_station_longitude  , t.end_station_latitude)
    ) AS distance_m,
    t.duration_sec AS duration_s
  FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips` AS t
  JOIN berkeley_stations bs
    ON bs.station_id = t.start_station_id                    -- trips that START in Berkeley
  WHERE t.duration_sec > 0
    AND t.start_station_longitude IS NOT NULL
    AND t.start_station_latitude  IS NOT NULL
    AND t.end_station_longitude   IS NOT NULL
    AND t.end_station_latitude    IS NOT NULL
)
SELECT
  ROUND(MAX(distance_m / duration_s), 1) AS highest_avg_speed_mps
FROM trips_with_speed
WHERE distance_m > 1000;                                     -- only long trips