/*  Shortest straight-line (great-circle) distance, in miles,
    from each “The Home Depot” store to its nearest
    “Lowe’s Home Improvement” location                       */

WITH
-- All Home Depot stores with coordinates
HD AS (
    SELECT
        p."POI_ID"                         AS "HD_POI_ID",
        p."POI_NAME"                       AS "HD_NAME",
        a."LATITUDE"                       AS "HD_LAT",
        a."LONGITUDE"                      AS "HD_LON"
    FROM  US_REAL_ESTATE.CYBERSYN.POINT_OF_INTEREST_INDEX                    p
    JOIN  US_REAL_ESTATE.CYBERSYN.POINT_OF_INTEREST_ADDRESSES_RELATIONSHIPS  pa
          ON p."POI_ID" = pa."POI_ID"
    JOIN  US_REAL_ESTATE.CYBERSYN.US_ADDRESSES                               a
          ON pa."ADDRESS_ID" = a."ADDRESS_ID"
    WHERE p."POI_NAME" ILIKE '%Home%Depot%'
),

-- All Lowe’s Home Improvement stores with coordinates
LOWES AS (
    SELECT
        p."POI_ID"                         AS "LOWES_POI_ID",
        p."POI_NAME"                       AS "LOWES_NAME",
        a."LATITUDE"                       AS "LOWES_LAT",
        a."LONGITUDE"                      AS "LOWES_LON"
    FROM  US_REAL_ESTATE.CYBERSYN.POINT_OF_INTEREST_INDEX                    p
    JOIN  US_REAL_ESTATE.CYBERSYN.POINT_OF_INTEREST_ADDRESSES_RELATIONSHIPS  pa
          ON p."POI_ID" = pa."POI_ID"
    JOIN  US_REAL_ESTATE.CYBERSYN.US_ADDRESSES                               a
          ON pa."ADDRESS_ID" = a."ADDRESS_ID"
    WHERE p."POI_NAME" ILIKE '%Lowe%s%Home%Improvement%'
)

SELECT
    hd."HD_POI_ID",
    hd."HD_NAME",
    lowes."LOWES_POI_ID",
    lowes."LOWES_NAME",
    -- convert Snowflake’s meter distance to miles (1 mile ≈ 1609 m)
    ST_DISTANCE(
        ST_MAKEPOINT(hd."HD_LON",    hd."HD_LAT"),
        ST_MAKEPOINT(lowes."LOWES_LON", lowes."LOWES_LAT")
    ) / 1609                               AS "DIST_MILES"
FROM    HD
CROSS JOIN LOWES
QUALIFY  ROW_NUMBER() OVER (
            PARTITION BY hd."HD_POI_ID"
            ORDER BY ST_DISTANCE(
                        ST_MAKEPOINT(hd."HD_LON",    hd."HD_LAT"),
                        ST_MAKEPOINT(lowes."LOWES_LON", lowes."LOWES_LAT")
                     )
        ) = 1          -- keep only the closest Lowe’s per Home Depot
ORDER BY "DIST_MILES" NULLS LAST;   -- optional ordering for easy review