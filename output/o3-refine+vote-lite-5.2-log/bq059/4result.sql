SELECT 
  ROUND(MAX(speed_m_per_s), 1) AS highest_avg_speed_m_s
FROM (
  SELECT
    ST_DISTANCE(
      ST_GEOGPOINT(t.start_station_longitude, t.start_station_latitude),
      ST_GEOGPOINT(t.end_station_longitude,   t.end_station_latitude)
    ) AS distance_m,
    t.duration_sec,
    ST_DISTANCE(
      ST_GEOGPOINT(t.start_station_longitude, t.start_station_latitude),
      ST_GEOGPOINT(t.end_station_longitude,   t.end_station_latitude)
    ) / t.duration_sec AS speed_m_per_s
  FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips` AS t
  JOIN `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info` AS si
    ON CAST(t.start_station_id AS STRING) = si.station_id
  WHERE si.region_id = 14                -- Berkeley stations
    AND t.duration_sec > 0               -- avoid division by zero
    AND t.start_station_latitude IS NOT NULL 
    AND t.end_station_latitude   IS NOT NULL
    AND t.start_station_longitude IS NOT NULL 
    AND t.end_station_longitude   IS NOT NULL
) 
WHERE distance_m > 1000;                -- trips longer than 1 km