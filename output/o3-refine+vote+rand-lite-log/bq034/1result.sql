SELECT
  id,
  name,
  state,
  latitude,
  longitude,
  ROUND(ST_DISTANCE(
          ST_GEOGPOINT(longitude, latitude),
          ST_GEOGPOINT(-87.6847, 41.8319)
        ) / 1000, 4) AS distance_km
FROM
  `bigquery-public-data.ghcn_d.ghcnd_stations`
WHERE
  ST_DISTANCE(
    ST_GEOGPOINT(longitude, latitude),
    ST_GEOGPOINT(-87.6847, 41.8319)
  ) <= 50000    -- 50 km in meters
ORDER BY
  distance_km ASC,
  id;