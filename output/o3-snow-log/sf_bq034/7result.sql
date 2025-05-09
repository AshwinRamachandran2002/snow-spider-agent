WITH chicago AS (
    SELECT 41.8319  AS "lat",
           -87.6847 AS "lon"
), station_distance AS (
    SELECT
        s."id",
        s."name",
        2 * 6371 *
        ASIN(
            SQRT(
                POWER(SIN((RADIANS(s."latitude"  - c."lat"))/2), 2) +
                COS(RADIANS(c."lat")) * COS(RADIANS(s."latitude")) *
                POWER(SIN((RADIANS(s."longitude" - c."lon"))/2), 2)
            )
        ) AS "distance_km"
    FROM GHCN_D.GHCN_D."GHCND_STATIONS" s
    CROSS JOIN chicago c
    WHERE s."latitude"  IS NOT NULL
      AND s."longitude" IS NOT NULL
)
SELECT "id",
       "name"
FROM   station_distance
WHERE  "distance_km" <= 50
ORDER  BY "distance_km" NULLS LAST;