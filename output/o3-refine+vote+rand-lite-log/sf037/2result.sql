WITH home_depot AS (   -- all “The Home Depot” locations with coordinates
    SELECT
        p."POI_ID"                AS "HOME_DEPOT_POI_ID",
        ST_MAKEPOINT(a."LONGITUDE", a."LATITUDE") AS "GEOM"
    FROM US_REAL_ESTATE.CYBERSYN.POINT_OF_INTEREST_INDEX                  p
    JOIN US_REAL_ESTATE.CYBERSYN.POINT_OF_INTEREST_ADDRESSES_RELATIONSHIPS r
          ON p."POI_ID" = r."POI_ID"
    JOIN US_REAL_ESTATE.CYBERSYN.US_ADDRESSES                             a
          ON r."ADDRESS_ID" = a."ADDRESS_ID"
    WHERE p."POI_NAME" = 'The Home Depot'
),
lowes AS (             -- all “Lowe’s Home Improvement” locations with coordinates
    SELECT
        p."POI_ID"                AS "LOWES_POI_ID",
        ST_MAKEPOINT(a."LONGITUDE", a."LATITUDE") AS "GEOM"
    FROM US_REAL_ESTATE.CYBERSYN.POINT_OF_INTEREST_INDEX                  p
    JOIN US_REAL_ESTATE.CYBERSYN.POINT_OF_INTEREST_ADDRESSES_RELATIONSHIPS r
          ON p."POI_ID" = r."POI_ID"
    JOIN US_REAL_ESTATE.CYBERSYN.US_ADDRESSES                             a
          ON r."ADDRESS_ID" = a."ADDRESS_ID"
    WHERE p."POI_NAME" = 'Lowe''s Home Improvement'
)

SELECT
    h."HOME_DEPOT_POI_ID",
    l."LOWES_POI_ID"                           AS "NEAREST_LOWES_POI_ID",
    ST_DISTANCE(h."GEOM", l."GEOM") / 1609     AS "DISTANCE_MILES"
FROM home_depot h
CROSS JOIN lowes  l
QUALIFY ROW_NUMBER() OVER (
            PARTITION BY h."HOME_DEPOT_POI_ID"
            ORDER BY ST_DISTANCE(h."GEOM", l."GEOM")
        ) = 1;