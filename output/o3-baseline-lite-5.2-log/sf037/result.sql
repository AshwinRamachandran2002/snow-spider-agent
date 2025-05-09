WITH "HOME_DEPOT" AS (
    SELECT
        p."POI_ID"                                                   AS "HD_POI_ID",
        ST_MAKEPOINT(a."LONGITUDE", a."LATITUDE")                    AS "HD_POINT"
    FROM US_REAL_ESTATE.CYBERSYN.POINT_OF_INTEREST_INDEX                    p
    JOIN US_REAL_ESTATE.CYBERSYN.POINT_OF_INTEREST_ADDRESSES_RELATIONSHIPS  r
      ON p."POI_ID" = r."POI_ID"
    JOIN US_REAL_ESTATE.CYBERSYN.US_ADDRESSES                               a
      ON r."ADDRESS_ID" = a."ADDRESS_ID"
    WHERE p."POI_NAME" = 'The Home Depot'
),
"LOWES" AS (
    SELECT
        p."POI_ID"                                                   AS "LOWES_POI_ID",
        ST_MAKEPOINT(a."LONGITUDE", a."LATITUDE")                    AS "LOWES_POINT"
    FROM US_REAL_ESTATE.CYBERSYN.POINT_OF_INTEREST_INDEX                    p
    JOIN US_REAL_ESTATE.CYBERSYN.POINT_OF_INTEREST_ADDRESSES_RELATIONSHIPS  r
      ON p."POI_ID" = r."POI_ID"
    JOIN US_REAL_ESTATE.CYBERSYN.US_ADDRESSES                               a
      ON r."ADDRESS_ID" = a."ADDRESS_ID"
    WHERE p."POI_NAME" = 'Lowe''s Home Improvement'
)
SELECT
    hd."HD_POI_ID"                                 AS "HOME_DEPOT_POI_ID",
    lw."LOWES_POI_ID"                              AS "NEAREST_LOWES_POI_ID",
    ST_DISTANCE(hd."HD_POINT", lw."LOWES_POINT") / 1609  AS "DISTANCE_MILES"
FROM "HOME_DEPOT" hd
CROSS JOIN "LOWES" lw
QUALIFY ROW_NUMBER() OVER (
           PARTITION BY hd."HD_POI_ID"
           ORDER BY ST_DISTANCE(hd."HD_POINT", lw."LOWES_POINT")
       ) = 1;