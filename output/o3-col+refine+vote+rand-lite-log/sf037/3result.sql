/*  Nearest-neighbor distance from every “The Home Depot” store
    to its closest “Lowe’s Home Improvement” location            */

WITH home_depot AS (
    SELECT
        i."POI_ID"                       AS "HD_POI_ID",
        a."LATITUDE"                     AS "HD_LAT",
        a."LONGITUDE"                    AS "HD_LON"
    FROM US_REAL_ESTATE.CYBERSYN.POINT_OF_INTEREST_INDEX                    i
    JOIN US_REAL_ESTATE.CYBERSYN.POINT_OF_INTEREST_ADDRESSES_RELATIONSHIPS  r
          ON i."POI_ID" = r."POI_ID"
    JOIN US_REAL_ESTATE.CYBERSYN.US_ADDRESSES                               a
          ON r."ADDRESS_ID" = a."ADDRESS_ID"
    WHERE i."POI_NAME" ILIKE '%home depot%'          -- all Home Depot POIs
),
lowes AS (
    SELECT
        i."POI_ID"                       AS "LOWES_POI_ID",
        a."LATITUDE"                     AS "LOWES_LAT",
        a."LONGITUDE"                    AS "LOWES_LON"
    FROM US_REAL_ESTATE.CYBERSYN.POINT_OF_INTEREST_INDEX                    i
    JOIN US_REAL_ESTATE.CYBERSYN.POINT_OF_INTEREST_ADDRESSES_RELATIONSHIPS  r
          ON i."POI_ID" = r."POI_ID"
    JOIN US_REAL_ESTATE.CYBERSYN.US_ADDRESSES                               a
          ON r."ADDRESS_ID" = a."ADDRESS_ID"
    WHERE i."POI_NAME" ILIKE '%lowe%home improvement%' -- all Lowe’s POIs
)

SELECT
    hd."HD_POI_ID",
    lowes."LOWES_POI_ID",
    ROUND(
        ST_DISTANCE(
            ST_MAKEPOINT(hd."HD_LON",     hd."HD_LAT"),
            ST_MAKEPOINT(lowes."LOWES_LON", lowes."LOWES_LAT")
        ) / 1609,                        -- convert meters → miles
        2
    )                                    AS "NEAREST_DIST_MILES"
FROM home_depot  hd
CROSS JOIN lowes
QUALIFY ROW_NUMBER() OVER (PARTITION BY hd."HD_POI_ID"
                           ORDER BY "NEAREST_DIST_MILES") = 1   -- keep nearest Lowe's
ORDER BY "NEAREST_DIST_MILES";