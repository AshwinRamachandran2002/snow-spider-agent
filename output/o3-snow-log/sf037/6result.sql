/*  nearest-Lowe’s distance (miles) for every Home Depot store */
WITH home_depot AS (
    SELECT
        p."POI_ID"    AS "HD_POI_ID",
        p."POI_NAME"  AS "HD_NAME",
        a."LONGITUDE" AS "HD_LONG",
        a."LATITUDE"  AS "HD_LAT"
    FROM US_REAL_ESTATE.CYBERSYN.POINT_OF_INTEREST_INDEX                   p
    JOIN US_REAL_ESTATE.CYBERSYN.POINT_OF_INTEREST_ADDRESSES_RELATIONSHIPS r
          ON r."POI_ID" = p."POI_ID"
    JOIN US_REAL_ESTATE.CYBERSYN.US_ADDRESSES                              a
          ON a."ADDRESS_ID" = r."ADDRESS_ID"
    WHERE p."POI_NAME" ILIKE '%home%depot%'           -- Home Depot locations
),
lowes AS (
    SELECT
        p."POI_ID"    AS "LOWES_POI_ID",
        p."POI_NAME"  AS "LOWES_NAME",
        a."LONGITUDE" AS "LOWES_LONG",
        a."LATITUDE"  AS "LOWES_LAT"
    FROM US_REAL_ESTATE.CYBERSYN.POINT_OF_INTEREST_INDEX                   p
    JOIN US_REAL_ESTATE.CYBERSYN.POINT_OF_INTEREST_ADDRESSES_RELATIONSHIPS r
          ON r."POI_ID" = p."POI_ID"
    JOIN US_REAL_ESTATE.CYBERSYN.US_ADDRESSES                              a
          ON a."ADDRESS_ID" = r."ADDRESS_ID"
    WHERE p."POI_NAME" ILIKE '%lowe%s home%improvement%' -- Lowe’s stores
)

SELECT
    hd."HD_POI_ID",
    hd."HD_NAME",
    lw."LOWES_POI_ID",
    lw."LOWES_NAME",
    ROUND(
        ST_DISTANCE(
            TO_GEOGRAPHY(ST_MAKEPOINT(hd."HD_LONG",  hd."HD_LAT")),
            TO_GEOGRAPHY(ST_MAKEPOINT(lw."LOWES_LONG", lw."LOWES_LAT"))
        ) / 1609 , 2                                              -- meters → miles
    ) AS "DISTANCE_MILES"
FROM home_depot hd
CROSS JOIN lowes lw
QUALIFY ROW_NUMBER() OVER (
            PARTITION BY hd."HD_POI_ID"
            ORDER BY ST_DISTANCE(
                       TO_GEOGRAPHY(ST_MAKEPOINT(hd."HD_LONG",  hd."HD_LAT")),
                       TO_GEOGRAPHY(ST_MAKEPOINT(lw."LOWES_LONG", lw."LOWES_LAT"))
                     )
        ) = 1;   -- keep only the closest Lowe’s for each Home Depot