SELECT
  id,
  name
FROM `bigquery-public-data.ghcn_d.ghcnd_stations`
WHERE
  -- 50 km = 50 000 m
  ST_DISTANCE(
    ST_GEOGPOINT(longitude, latitude),
    ST_GEOGPOINT(-87.6847, 41.8319)   -- Chicago city center
  ) <= 50000
ORDER BY
  ST_DISTANCE(
    ST_GEOGPOINT(longitude, latitude),
    ST_GEOGPOINT(-87.6847, 41.8319)
  );