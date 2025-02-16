-- Task: I want to know the IDs, names, and straight-line distances from the center of Chicago for the first 100 weather stations.
SELECT
  `id`,
  `name`,
  ST_DISTANCE(
    ST_GEOGPOINT(`longitude`, `latitude`),
    ST_GEOGPOINT(-87.6847, 41.8319)
  ) AS distance_to_chicago
FROM
  `bigquery-public-data.ghcn_d.ghcnd_stations`
LIMIT 100;