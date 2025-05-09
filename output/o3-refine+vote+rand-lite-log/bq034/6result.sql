-- Weather stations within 50 km of Chicago’s center (41.8319 N, -87.6847 W)
WITH chicago AS (
  SELECT ST_GEOGPOINT(-87.6847, 41.8319) AS geog
)
SELECT
  s.id,
  s.name,
  ROUND(ST_DISTANCE(ST_GEOGPOINT(s.longitude, s.latitude), c.geog) / 1000, 2) AS distance_km
FROM
  `bigquery-public-data.ghcn_d.ghcnd_stations` AS s
CROSS JOIN
  chicago AS c
WHERE
  s.latitude IS NOT NULL
  AND s.longitude IS NOT NULL
  AND ST_DISTANCE(ST_GEOGPOINT(s.longitude, s.latitude), c.geog) <= 50000  -- 50 km
ORDER BY
  distance_km ASC,
  s.id;