WITH berkeley_trips AS (
  SELECT
    t.trip_id,
    -- distance in meters between start and end points
    ST_DISTANCE(
      ST_GEOGPOINT(t.start_station_longitude, t.start_station_latitude),
      ST_GEOGPOINT(t.end_station_longitude,   t.end_station_latitude)
    ) AS trip_meters,
    t.duration_sec
  FROM
    `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips` AS t
  JOIN
    `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info` AS si
    ON CAST(si.station_id AS INT64) = t.start_station_id
  JOIN
    `bigquery-public-data.san_francisco_bikeshare.bikeshare_regions` AS r
    ON r.region_id = si.region_id
  WHERE
    r.name = 'Berkeley'
    AND t.start_station_longitude IS NOT NULL
    AND t.end_station_longitude   IS NOT NULL
    AND t.start_station_latitude IS NOT NULL
    AND t.end_station_latitude   IS NOT NULL
    AND t.duration_sec > 0
),
speed_stats AS (
  SELECT
    trip_meters / duration_sec AS speed_mps
  FROM
    berkeley_trips
  WHERE
    trip_meters > 1000          -- only consider trips longer than 1 000 m
)
SELECT
  ROUND(MAX(speed_mps), 1) AS highest_avg_speed_mps
FROM
  speed_stats;