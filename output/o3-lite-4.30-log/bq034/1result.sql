SELECT
  id AS station_id,
  name AS station_name,
  FORMAT('POINT(%.6f %.6f)', longitude, latitude) AS travel_coordinates,
  FORMAT('%.4f', dist_km) AS cumulative_travel_distance_km
FROM (
  SELECT
    id,
    name,
    longitude,
    latitude,
    ST_DISTANCE(
      ST_GEOGPOINT(longitude, latitude),
      ST_GEOGPOINT(-87.6847, 41.8319)
    ) / 1000 AS dist_km
  FROM `bigquery-public-data.ghcn_d.ghcnd_stations`
  WHERE latitude IS NOT NULL
    AND longitude IS NOT NULL
) sub
WHERE dist_km <= 50
ORDER BY dist_km, station_id;