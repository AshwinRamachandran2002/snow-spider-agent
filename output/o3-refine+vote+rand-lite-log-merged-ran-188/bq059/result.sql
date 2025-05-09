WITH berkeley_trips AS (
  SELECT
    ST_DISTANCE(t.start_station_geom, t.end_station_geom) AS distance_m,
    t.duration_sec,
    ST_DISTANCE(t.start_station_geom, t.end_station_geom) / t.duration_sec AS speed_mps
  FROM
    `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips` AS t
  JOIN
    `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info` AS s
  ON
    CAST(t.start_station_id AS STRING) = s.station_id
  WHERE
    s.region_id = 14                -- Berkeley start stations
    AND t.duration_sec > 0          -- avoid divide‑by‑zero
)
SELECT
  ROUND(MAX(speed_mps), 1) AS highest_avg_speed_mps
FROM
  berkeley_trips
WHERE
  distance_m > 1000;                -- trips longer than 1 km