WITH nearby AS (
  SELECT
    id,
    name,
    latitude,
    longitude,
    ST_Distance(
      ST_GeogPoint(-87.6847, 41.8319),          -- Chicago centre (lon, lat)
      ST_GeogPoint(longitude, latitude)         -- station location
    ) / 1000 AS dist_km                         -- convert to kilometres
  FROM `bigquery-public-data.ghcn_d.ghcnd_stations`
)
SELECT
  id                                   AS station_id,
  name                                 AS station_name,
  FORMAT('%.4f,%.4f', latitude, longitude) AS travel_coordinates,
  FORMAT('%.4f', dist_km)                  AS cumulative_travel_distance_km
FROM nearby
WHERE dist_km <= 50
ORDER BY dist_km, station_id;