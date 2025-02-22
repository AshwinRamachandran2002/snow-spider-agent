-- Task: Calculate the distance for each bikeshare trip in the San Francisco Bikeshare program using data from bikeshare trips and stations. Show only the first 100 results.
SELECT
  starts.trip_id,
  starts.bike_number,
  ST_DISTANCE(
    ST_GEOGPOINT(start_lon, start_lat),
    ST_GEOGPOINT(end_lon, end_lat)
  ) AS dist_in_m
FROM (
  SELECT 
    latitude AS start_lat,
    longitude AS start_lon,
    bike_number,
    trip_id
  FROM `bigquery-public-data.san_francisco.bikeshare_trips` trips
  LEFT JOIN `bigquery-public-data.san_francisco.bikeshare_stations` stations
    ON trips.start_station_id = stations.station_id
) starts
LEFT JOIN (
  SELECT 
    latitude AS end_lat,
    longitude AS end_lon,
    bike_number,
    trip_id
  FROM `bigquery-public-data.san_francisco.bikeshare_trips` trips
  LEFT JOIN `bigquery-public-data.san_francisco.bikeshare_stations` stations
    ON trips.end_station_id = stations.station_id
) ends ON ends.trip_id = starts.trip_id
LIMIT 100