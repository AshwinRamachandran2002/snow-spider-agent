SELECT DISTINCT
       "id",
       "name"
FROM   "GHCN_D"."GHCN_D"."GHCND_STATIONS"
WHERE  "latitude" IS NOT NULL
  AND  "longitude" IS NOT NULL
  AND  6371 * ACOS(
          COS(RADIANS(41.8319)) * COS(RADIANS("latitude")) * COS(RADIANS("longitude") - RADIANS(-87.6847))
          + SIN(RADIANS(41.8319)) * SIN(RADIANS("latitude"))
       ) <= 50;