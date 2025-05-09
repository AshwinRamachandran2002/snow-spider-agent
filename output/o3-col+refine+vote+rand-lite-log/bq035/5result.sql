-- Total distance (in kilometers) traveled by each bike in the SF Bikeshare program
WITH trip_distances AS (
  SELECT
    t.bike_number,
    -- ST_DISTANCE returns meters; convert to kilometers
    ST_DISTANCE(
      ST_GeogPoint(s_start.longitude, s_start.latitude),
      ST_GeogPoint(s_end.longitude,   s_end.latitude)
    ) / 1000 AS trip_km
  FROM `bigquery-public-data.san_francisco.bikeshare_trips`     AS t
  JOIN `bigquery-public-data.san_francisco.bikeshare_stations`  AS s_start
       ON t.start_station_id = s_start.station_id
  JOIN `bigquery-public-data.san_francisco.bikeshare_stations`  AS s_end
       ON t.end_station_id   = s_end.station_id
)

SELECT
  bike_number,
  ROUND(SUM(trip_km), 2) AS total_distance_km
FROM trip_distances
GROUP BY bike_number
ORDER BY total_distance_km DESC;