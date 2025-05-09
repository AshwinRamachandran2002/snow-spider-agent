-- Total distance (in miles) traveled by each bike in the SF Bikeshare program
WITH stations AS (
  SELECT
    station_id,
    latitude,
    longitude
  FROM `bigquery-public-data.san_francisco.bikeshare_stations`
),

trips AS (
  SELECT
    t.bike_number,
    -- Convert meters returned by ST_DISTANCE to miles
    ST_DISTANCE(
      ST_GEOGPOINT(s_start.longitude, s_start.latitude),
      ST_GEOGPOINT(s_end.longitude,   s_end.latitude)
    ) / 1609.34 AS trip_miles
  FROM `bigquery-public-data.san_francisco.bikeshare_trips` AS t
  JOIN stations AS s_start
    ON t.start_station_id = s_start.station_id
  JOIN stations AS s_end
    ON t.end_station_id   = s_end.station_id
)

SELECT
  bike_number,
  ROUND(SUM(trip_miles), 2) AS total_miles_travelled
FROM trips
GROUP BY bike_number
ORDER BY total_miles_travelled DESC;