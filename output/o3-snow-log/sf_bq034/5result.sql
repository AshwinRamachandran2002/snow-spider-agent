WITH chicago AS (
    SELECT TO_GEOGRAPHY('POINT(-87.6847 41.8319)') AS "geom"
)
SELECT 
    s."id",
    s."name"
FROM "GHCN_D"."GHCN_D"."GHCND_STATIONS" s
JOIN chicago c
    ON ST_DISTANCE(
           c."geom",
           ST_MAKEPOINT(s."longitude", s."latitude")
       ) <= 50000   -- distance in meters (50 km)
WHERE s."latitude" IS NOT NULL 
  AND s."longitude" IS NOT NULL
ORDER BY ST_DISTANCE(
            c."geom",
            ST_MAKEPOINT(s."longitude", s."latitude")
         ) ASC NULLS LAST;