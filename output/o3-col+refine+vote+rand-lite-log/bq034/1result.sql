SELECT
  `id`,
  `name`
FROM
  `bigquery-public-data.ghcn_d.ghcnd_stations`
WHERE
  ST_DISTANCE(
    ST_GEOGPOINT(`longitude`, `latitude`),
    ST_GEOGPOINT(-87.6847, 41.8319)   -- Chicago city centre
  ) <= 50 * 1000   -- 50 km in metres
ORDER BY
  ST_DISTANCE(
    ST_GEOGPOINT(`longitude`, `latitude`),
    ST_GEOGPOINT(-87.6847, 41.8319)
  );