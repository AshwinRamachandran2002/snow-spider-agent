WITH "HOME_DEPOT" AS (   -- all The Home Depot stores with coordinates
    SELECT
        p."POI_ID"                       AS "HD_POI_ID",
        a."LONGITUDE",
        a."LATITUDE",
        ST_MAKEPOINT(a."LONGITUDE", a."LATITUDE")   AS "HD_GEOM"
    FROM US_REAL_ESTATE.CYBERSYN.POINT_OF_INTEREST_INDEX                     p
    JOIN US_REAL_ESTATE.CYBERSYN.POINT_OF_INTEREST_ADDRESSES_RELATIONSHIPS   r
          ON p."POI_ID" = r."POI_ID"
    JOIN US_REAL_ESTATE.CYBERSYN.US_ADDRESSES                                a
          ON r."ADDRESS_ID" = a."ADDRESS_ID"
    WHERE p."POI_NAME"  = 'The Home Depot'
      AND a."LONGITUDE" IS NOT NULL
      AND a."LATITUDE"  IS NOT NULL
), 
"LOWES" AS (            -- all Lowe's Home Improvement stores with coordinates
    SELECT
        p."POI_ID"                       AS "LOWES_POI_ID",
        a."LONGITUDE",
        a."LATITUDE",
        ST_MAKEPOINT(a."LONGITUDE", a."LATITUDE")   AS "LOWES_GEOM"
    FROM US_REAL_ESTATE.CYBERSYN.POINT_OF_INTEREST_INDEX                     p
    JOIN US_REAL_ESTATE.CYBERSYN.POINT_OF_INTEREST_ADDRESSES_RELATIONSHIPS   r
          ON p."POI_ID" = r."POI_ID"
    JOIN US_REAL_ESTATE.CYBERSYN.US_ADDRESSES                                a
          ON r."ADDRESS_ID" = a."ADDRESS_ID"
    WHERE p."POI_NAME"  = 'Lowe''s Home Improvement'
      AND a."LONGITUDE" IS NOT NULL
      AND a."LATITUDE"  IS NOT NULL
)
SELECT
    hd."HD_POI_ID",                       -- The Home Depot store
    lw."LOWES_POI_ID"        AS "NEAREST_LOWES_POI_ID",   -- nearest Lowe's
    ST_DISTANCE(hd."HD_GEOM", lw."LOWES_GEOM") / 1609     AS "DISTANCE_MILES"
FROM "HOME_DEPOT" hd
CROSS JOIN "LOWES"  lw
QUALIFY ROW_NUMBER() OVER (
            PARTITION BY hd."HD_POI_ID"
            ORDER BY ST_DISTANCE(hd."HD_GEOM", lw."LOWES_GEOM")
        ) = 1;