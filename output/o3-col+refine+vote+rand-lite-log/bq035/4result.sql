-- Total distance (in miles) travelled by each bike
WITH station_locations AS (
  SELECT
    station_id,
    ST_GEOGPOINT(longitude, latitude) AS geog
  FROM
    `bigquery-public-data.san_francisco.bikeshare_stations`
),
trip_with_distance AS (
  SELECT
    t.bike_number,
    -- convert meters (ST_DISTANCE default) to miles
    ST_DISTANCE(start_loc.geog, end_loc.geog) / 1609.34 AS trip_miles
  FROM
    `bigquery-public-data.san_francisco.bikeshare_trips` AS t
  JOIN
    station_locations AS start_loc
    ON t.start_station_id = start_loc.station_id
  JOIN
    station_locations AS end_loc
    ON t.end_station_id = end_loc.station_id
)
SELECT
  bike_number,
  ROUND(SUM(trip_miles), 2) AS total_miles
FROM
  trip_with_distance
GROUP BY
  bike_number
ORDER BY
  bike_number;