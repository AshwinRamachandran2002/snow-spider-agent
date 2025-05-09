SELECT
  id,
  name
FROM
  `bigquery-public-data.ghcn_d.ghcnd_stations`
WHERE
  latitude  IS NOT NULL
  AND longitude IS NOT NULL
  -- distance is returned in metres; 50 km = 50 000 m
  AND ST_DISTANCE(
        ST_GEOGPOINT(longitude, latitude),   -- station location
        ST_GEOGPOINT(-87.6847, 41.8319)      -- Chicago centre
      ) <= 50000
ORDER BY
  ST_DISTANCE(
        ST_GEOGPOINT(longitude, latitude),
        ST_GEOGPOINT(-87.6847, 41.8319)
      );