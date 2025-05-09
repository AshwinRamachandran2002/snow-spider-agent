SELECT
  id,
  name
FROM
  `bigquery-public-data.ghcn_d.ghcnd_stations`
WHERE
  latitude IS NOT NULL
  AND longitude IS NOT NULL
  AND ST_DISTANCE(
        ST_GEOGPOINT(longitude, latitude),
        ST_GEOGPOINT(-87.6847, 41.8319)   -- Chicago city center (lon, lat)
      ) <= 50000                          -- 50 km in metres
ORDER BY
  id;