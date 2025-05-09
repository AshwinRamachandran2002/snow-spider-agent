-- Total distance travelled (in kilometres) by every bike in the SF Bikeshare programme
WITH stations AS (
  SELECT
    station_id,
    latitude,
    longitude
  FROM `bigquery-public-data.san_francisco.bikeshare_stations`
),
trip_distances AS (
  SELECT
    t.bike_number AS bike_id,
    -- distance between start‑ and end‑station; divide by 1000 to convert metres→km
    CASE
      WHEN s_start.latitude  IS NULL OR s_start.longitude IS NULL
        OR s_end.latitude    IS NULL OR s_end.longitude   IS NULL
      THEN 0
      ELSE ST_DISTANCE(
             ST_GEOGPOINT(s_start.longitude, s_start.latitude),
             ST_GEOGPOINT(s_end.longitude,   s_end.latitude)
           ) / 1000.0
    END AS trip_distance_km
  FROM `bigquery-public-data.san_francisco.bikeshare_trips` AS t
  LEFT JOIN stations AS s_start
         ON t.start_station_id = s_start.station_id
  LEFT JOIN stations AS s_end
         ON t.end_station_id   = s_end.station_id
)
SELECT
  bike_id,
  ROUND(SUM(trip_distance_km), 4) AS total_distance_km
FROM trip_distances
GROUP BY bike_id
ORDER BY total_distance_km DESC;