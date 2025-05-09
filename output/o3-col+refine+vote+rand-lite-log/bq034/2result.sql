-- IDs and names of GHCN-D stations within 50 km of Chicago city centre
SELECT
  `id`,
  `name`
FROM `bigquery-public-data.ghcn_d.ghcnd_stations`
WHERE
  ST_DISTANCE(
    ST_GEOGPOINT(`longitude`, `latitude`),                 -- station location
    ST_GEOGPOINT(-87.6847, 41.8319)                        -- Chicago centre
  ) <= 50000                                               -- 50 km (50 000 m)
ORDER BY
  ST_DISTANCE(
    ST_GEOGPOINT(`longitude`, `latitude`),
    ST_GEOGPOINT(-87.6847, 41.8319)
  );