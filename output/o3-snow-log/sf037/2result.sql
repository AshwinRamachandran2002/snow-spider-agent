/*  Nearest-store distance: each “The Home Depot” to its closest “Lowe’s Home Improvement”  */

WITH home_depot AS (   -- all Home Depot stores with coordinates
    SELECT  p."POI_ID"    AS "HD_POI_ID",
            p."POI_NAME"  AS "HD_NAME",
            a."LATITUDE"  AS "HD_LAT",
            a."LONGITUDE" AS "HD_LON"
    FROM   US_REAL_ESTATE.CYBERSYN.POINT_OF_INTEREST_INDEX                    p
    JOIN   US_REAL_ESTATE.CYBERSYN.POINT_OF_INTEREST_ADDRESSES_RELATIONSHIPS  r
           ON p."POI_ID" = r."POI_ID"
    JOIN   US_REAL_ESTATE.CYBERSYN.US_ADDRESSES                               a
           ON r."ADDRESS_ID" = a."ADDRESS_ID"
    WHERE  p."POI_NAME" = 'The Home Depot'        -- exact brand match
),

lowes AS (         -- all Lowe’s stores with coordinates
    SELECT  p."POI_ID"    AS "LOWES_POI_ID",
            p."POI_NAME"  AS "LOWES_NAME",
            a."LATITUDE"  AS "LOWES_LAT",
            a."LONGITUDE" AS "LOWES_LON"
    FROM   US_REAL_ESTATE.CYBERSYN.POINT_OF_INTEREST_INDEX                    p
    JOIN   US_REAL_ESTATE.CYBERSYN.POINT_OF_INTEREST_ADDRESSES_RELATIONSHIPS  r
           ON p."POI_ID" = r."POI_ID"
    JOIN   US_REAL_ESTATE.CYBERSYN.US_ADDRESSES                               a
           ON r."ADDRESS_ID" = a."ADDRESS_ID"
    WHERE  p."POI_NAME" = 'Lowe''s Home Improvement'  -- exact brand match
)

SELECT
       h."HD_POI_ID",
       h."HD_NAME",
       l."LOWES_POI_ID",
       l."LOWES_NAME",
       ST_DISTANCE(
           ST_MAKEPOINT(h."HD_LON", h."HD_LAT"),     -- Home Depot point
           ST_MAKEPOINT(l."LOWES_LON", l."LOWES_LAT")-- Lowe’s point
       ) / 1609      AS "NEAREST_DISTANCE_MILES"     -- convert metres → miles
FROM   home_depot h
CROSS  JOIN lowes  l
QUALIFY  ROW_NUMBER() OVER (PARTITION BY h."HD_POI_ID"
                            ORDER BY ST_DISTANCE(
                                      ST_MAKEPOINT(h."HD_LON", h."HD_LAT"),
                                      ST_MAKEPOINT(l."LOWES_LON", l."LOWES_LAT")
                                    )
                           ) = 1        -- keep only the closest Lowe’s per store
ORDER BY "NEAREST_DISTANCE_MILES" NULLS LAST;