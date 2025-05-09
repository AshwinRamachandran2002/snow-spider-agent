SELECT DISTINCT
  id,
  name
FROM `bigquery-public-data.ghcn_d.ghcnd_stations`
WHERE ST_DISTANCE(
        ST_GEOGPOINT(longitude, latitude),   -- station coordinates
        ST_GEOGPOINT(-87.6847, 41.8319)      -- Chicago city centre
      ) <= 50000                             -- 50 km (metres)
ORDER BY id;