SELECT
  id,
  name,
  latitude,
  longitude,
  ROUND(
    ST_DISTANCE(
      ST_GEOGPOINT(longitude, latitude),
      ST_GEOGPOINT(-87.6847, 41.8319)      -- Chicago (lon, lat)
    ) / 1000,                              -- convert metres → kilometres
    2
  ) AS distance_km
FROM `bigquery-public-data.ghcn_d.ghcnd_stations`
WHERE latitude  IS NOT NULL
  AND longitude IS NOT NULL
  AND ST_DISTANCE(
        ST_GEOGPOINT(longitude, latitude),
        ST_GEOGPOINT(-87.6847, 41.8319)
      ) <= 50000                           -- 50 km in metres
ORDER BY distance_km, id;