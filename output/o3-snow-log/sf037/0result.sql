/*--------------------------------------------------------------------
  For every “The Home Depot” (HD) location, find the straight-line
  distance (in miles) to its single nearest “Lowe’s Home Improvement”.
--------------------------------------------------------------------*/
WITH home_depot AS (   -- all Home Depot stores with lat/long
    SELECT
        poi."POI_ID"     AS "HD_POI_ID",
        addr."LATITUDE"  AS "HD_LAT",
        addr."LONGITUDE" AS "HD_LON"
    FROM US_REAL_ESTATE.CYBERSYN.POINT_OF_INTEREST_INDEX                 AS poi
    JOIN US_REAL_ESTATE.CYBERSYN.POINT_OF_INTEREST_ADDRESSES_RELATIONSHIPS AS rel
          ON poi."POI_ID" = rel."POI_ID"
    JOIN US_REAL_ESTATE.CYBERSYN.US_ADDRESSES                            AS addr
          ON rel."ADDRESS_ID" = addr."ADDRESS_ID"
    WHERE poi."POI_NAME" ILIKE '%home%depot%'                        -- catch variants
),

lowes AS (           -- all Lowe’s Home Improvement stores with lat/long
    SELECT
        poi."POI_ID"     AS "LOWES_POI_ID",
        addr."LATITUDE"  AS "LOWES_LAT",
        addr."LONGITUDE" AS "LOWES_LON"
    FROM US_REAL_ESTATE.CYBERSYN.POINT_OF_INTEREST_INDEX                 AS poi
    JOIN US_REAL_ESTATE.CYBERSYN.POINT_OF_INTEREST_ADDRESSES_RELATIONSHIPS AS rel
          ON poi."POI_ID" = rel."POI_ID"
    JOIN US_REAL_ESTATE.CYBERSYN.US_ADDRESSES                            AS addr
          ON rel."ADDRESS_ID" = addr."ADDRESS_ID"
    WHERE poi."POI_NAME" ILIKE '%lowe%home%improve%'                 -- catch variants
)

SELECT
    h."HD_POI_ID",                    -- Home Depot store
    l."LOWES_POI_ID",                -- Nearest Lowe’s store
    ROUND(                            -- distance in miles (4-decimals)
        ST_DISTANCE(
            ST_MAKEPOINT(h."HD_LON",    h."HD_LAT"),
            ST_MAKEPOINT(l."LOWES_LON", l."LOWES_LAT")
        ) / 1609,
        4
    )  AS "DIST_MILES"
FROM home_depot h
CROSS JOIN lowes l                     -- compare every HD to every Lowe’s
QUALIFY ROW_NUMBER() OVER (            -- keep only the closest Lowe’s
            PARTITION BY h."HD_POI_ID"
            ORDER BY "DIST_MILES"
        ) = 1
ORDER BY "DIST_MILES" NULLS LAST;      -- smallest distances first