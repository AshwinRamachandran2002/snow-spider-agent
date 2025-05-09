WITH berkeley_trips AS (
  SELECT
    t.trip_id,
    t.duration_sec,
    -- distance between start & end stations (in metres)
    ST_DISTANCE(
      ST_GEOGPOINT(t.start_station_longitude, t.start_station_latitude),
      ST_GEOGPOINT(t.end_station_longitude,   t.end_station_latitude)
    ) AS distance_m,
    -- average speed for the trip (m/s)
    ST_DISTANCE(
      ST_GEOGPOINT(t.start_station_longitude, t.start_station_latitude),
      ST_GEOGPOINT(t.end_station_longitude,   t.end_station_latitude)
    ) / t.duration_sec AS speed_m_s
  FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips`         AS t
  JOIN `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info`  AS si
       ON si.station_id = CAST(t.start_station_id AS STRING)
  JOIN `bigquery-public-data.san_francisco_bikeshare.bikeshare_regions`       AS r
       ON si.region_id = r.region_id
  WHERE r.name = 'Berkeley'        -- trips that start in Berkeley
    AND t.duration_sec > 0         -- avoid divide‑by‑zero
)

SELECT
  ROUND(MAX(speed_m_s), 1) AS highest_avg_speed_m_s
FROM berkeley_trips
WHERE distance_m > 1000;            -- only consider trips > 1 km