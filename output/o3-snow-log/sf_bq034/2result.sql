WITH center AS (
    SELECT 
        41.8319 AS "center_lat",
       -87.6847 AS "center_lon"
)
SELECT 
    s."id",
    s."name"
FROM 
    GHCN_D.GHCN_D."GHCND_STATIONS" AS s
CROSS JOIN 
    center c
WHERE 
    s."latitude" IS NOT NULL 
    AND s."longitude" IS NOT NULL
    AND 6371 * 2 * ASIN(
            SQRT(
                POWER(SIN(RADIANS(s."latitude"  - c."center_lat") / 2), 2) +
                COS(RADIANS(c."center_lat")) * COS(RADIANS(s."latitude")) *
                POWER(SIN(RADIANS(s."longitude" - c."center_lon") / 2), 2)
            )
        ) <= 50  -- distance in kilometres