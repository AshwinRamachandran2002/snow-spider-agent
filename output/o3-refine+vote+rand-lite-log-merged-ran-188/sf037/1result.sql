/*  Nearest-neighbor distance (in miles) from every “The Home Depot” POI
    to the closest “Lowe’s Home Improvement” POI                       */

WITH home_depot AS (   -- all Home Depot locations w/ coordinates
    SELECT
        hd."POI_ID"                AS "HD_POI_ID",
        ua."LATITUDE"              AS "HD_LAT",
        ua."LONGITUDE"             AS "HD_LON"
    FROM US_REAL_ESTATE.CYBERSYN.POINT_OF_INTEREST_INDEX               hd
    JOIN US_REAL_ESTATE.CYBERSYN.POINT_OF_INTEREST_ADDRESSES_RELATIONSHIPS rel
         ON rel."POI_ID" = hd."POI_ID"
    JOIN US_REAL_ESTATE.CYBERSYN.US_ADDRESSES                          ua
         ON ua."ADDRESS_ID" = rel."ADDRESS_ID"
    WHERE hd."POI_NAME" ILIKE '%home%depot%'                 -- The Home Depot
),

lowes AS (             -- all Lowe’s locations w/ coordinates
    SELECT
        lw."POI_ID"                AS "LOWES_POI_ID",
        ua."LATITUDE"              AS "L_LAT",
        ua."LONGITUDE"             AS "L_LON"
    FROM US_REAL_ESTATE.CYBERSYN.POINT_OF_INTEREST_INDEX               lw
    JOIN US_REAL_ESTATE.CYBERSYN.POINT_OF_INTEREST_ADDRESSES_RELATIONSHIPS rel
         ON rel."POI_ID" = lw."POI_ID"
    JOIN US_REAL_ESTATE.CYBERSYN.US_ADDRESSES                          ua
         ON ua."ADDRESS_ID" = rel."ADDRESS_ID"
    WHERE lw."POI_NAME" ILIKE '%lowe%home%improv%'           -- Lowe’s Home Improvement
       OR lw."POI_NAME" ILIKE '%lowe''s%'                    -- Lowe's
)

SELECT
    hd."HD_POI_ID",
    l."LOWES_POI_ID"                          AS "NEAREST_LOWES_POI_ID",
    ST_DISTANCE(
        ST_MAKEPOINT(hd."HD_LON", hd."HD_LAT"),
        ST_MAKEPOINT(l."L_LON",  l."L_LAT")
    ) / 1609                                  AS "MIN_DISTANCE_MILES"
FROM   home_depot hd
JOIN   lowes     l
       ON TRUE
QUALIFY ROW_NUMBER()
        OVER (PARTITION BY hd."HD_POI_ID" ORDER BY "MIN_DISTANCE_MILES") = 1
ORDER  BY "MIN_DISTANCE_MILES";