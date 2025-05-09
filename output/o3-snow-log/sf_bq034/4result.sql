SELECT
    "id",
    "name"
FROM GHCN_D.GHCN_D.GHCND_STATIONS
WHERE ST_DISTANCE(
          ST_POINT("longitude", "latitude"),   -- station location
          ST_POINT(-87.6847, 41.8319)          -- Chicago city-center
      ) <= 50000                               -- 50 km  (distance is in metres)
ORDER BY "name";