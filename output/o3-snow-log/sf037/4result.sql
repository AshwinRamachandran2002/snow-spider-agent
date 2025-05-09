/*  Shortest straight-line (great–circle) distance, in miles, from every
    “The Home Depot” store to its closest “Lowe’s Home Improvement”.        */

WITH home_depot AS (
    SELECT  poi."POI_ID"                                            AS "HD_POI_ID",
            poi."POI_NAME"                                          AS "HD_NAME",
            ST_POINT(addr."LONGITUDE", addr."LATITUDE")             AS "HD_POINT"
    FROM    US_REAL_ESTATE.CYBERSYN."POINT_OF_INTEREST_INDEX"                    poi
    JOIN    US_REAL_ESTATE.CYBERSYN."POINT_OF_INTEREST_ADDRESSES_RELATIONSHIPS"  rel
              ON rel."POI_ID" = poi."POI_ID"
    JOIN    US_REAL_ESTATE.CYBERSYN."US_ADDRESSES"                                addr
              ON addr."ADDRESS_ID" = rel."ADDRESS_ID"
    -- keep only “The Home Depot” stores
    WHERE   poi."POI_NAME" ILIKE 'The Home Depot%'
),

lowes AS (
    SELECT  poi."POI_ID"                                            AS "LOWES_POI_ID",
            poi."POI_NAME"                                          AS "LOWES_NAME",
            ST_POINT(addr."LONGITUDE", addr."LATITUDE")             AS "LOWES_POINT"
    FROM    US_REAL_ESTATE.CYBERSYN."POINT_OF_INTEREST_INDEX"                    poi
    JOIN    US_REAL_ESTATE.CYBERSYN."POINT_OF_INTEREST_ADDRESSES_RELATIONSHIPS"  rel
              ON rel."POI_ID" = poi."POI_ID"
    JOIN    US_REAL_ESTATE.CYBERSYN."US_ADDRESSES"                                addr
              ON addr."ADDRESS_ID" = rel."ADDRESS_ID"
    -- keep only “Lowe’s Home Improvement” locations
    WHERE   poi."POI_NAME" ILIKE 'Lowe''s Home Improvement%'
)

SELECT   hd."HD_POI_ID",
         hd."HD_NAME",
         lw."LOWES_POI_ID",
         lw."LOWES_NAME",
         ST_DISTANCE(hd."HD_POINT", lw."LOWES_POINT") / 1609    AS "DIST_MILES"
FROM     home_depot  hd
CROSS JOIN lowes     lw
QUALIFY   ROW_NUMBER() OVER (PARTITION BY hd."HD_POI_ID"
                             ORDER BY ST_DISTANCE(hd."HD_POINT", lw."LOWES_POINT")) = 1
ORDER BY  "DIST_MILES"  -- optional: see the closest pairs first
;