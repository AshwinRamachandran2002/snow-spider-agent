/*  Nearest Lowe’s Home Improvement location for every The Home Depot store  */
WITH home_depot AS (   -- all Home Depot POIs with coordinates
    SELECT 
        poi."POI_ID"               AS "HD_POI_ID",
        addr."LATITUDE"            AS "HD_LAT",
        addr."LONGITUDE"           AS "HD_LON"
    FROM US_REAL_ESTATE.CYBERSYN.POINT_OF_INTEREST_INDEX                poi
    JOIN US_REAL_ESTATE.CYBERSYN.POINT_OF_INTEREST_ADDRESSES_RELATIONSHIPS rel
      ON poi."POI_ID" = rel."POI_ID"
    JOIN US_REAL_ESTATE.CYBERSYN.US_ADDRESSES                           addr
      ON rel."ADDRESS_ID" = addr."ADDRESS_ID"
    WHERE poi."POI_NAME" ILIKE '%home%depot%'               -- The Home Depot
), 
lowes AS (              -- all Lowe’s POIs with coordinates
    SELECT 
        poi."POI_ID"               AS "LW_POI_ID",
        addr."LATITUDE"            AS "LW_LAT",
        addr."LONGITUDE"           AS "LW_LON"
    FROM US_REAL_ESTATE.CYBERSYN.POINT_OF_INTEREST_INDEX                poi
    JOIN US_REAL_ESTATE.CYBERSYN.POINT_OF_INTEREST_ADDRESSES_RELATIONSHIPS rel
      ON poi."POI_ID" = rel."POI_ID"
    JOIN US_REAL_ESTATE.CYBERSYN.US_ADDRESSES                           addr
      ON rel."ADDRESS_ID" = addr."ADDRESS_ID"
    WHERE poi."POI_NAME" ILIKE '%lowe%s home%improvement%'              -- Lowe’s patterns
       OR poi."POI_NAME" ILIKE '%lowe%home%improvement%'
)
SELECT
    hd."HD_POI_ID"                                           AS "HOME_DEPOT_POI_ID",
    lw."LW_POI_ID"                                           AS "LOWES_POI_ID",
    ST_DISTANCE(
        ST_MAKEPOINT(hd."HD_LON", hd."HD_LAT"),
        ST_MAKEPOINT(lw."LW_LON", lw."LW_LAT")
    ) / 1609                                                 AS "DISTANCE_MILES"   -- meters → miles
FROM home_depot hd
CROSS JOIN lowes lw
QUALIFY ROW_NUMBER() OVER (                                   -- keep only nearest Lowe’s per HD
           PARTITION BY hd."HD_POI_ID"
           ORDER BY ST_DISTANCE(
                     ST_MAKEPOINT(hd."HD_LON", hd."HD_LAT"),
                     ST_MAKEPOINT(lw."LW_LON", lw."LW_LAT")
                   )
       ) = 1
ORDER BY "DISTANCE_MILES" NULLS LAST;