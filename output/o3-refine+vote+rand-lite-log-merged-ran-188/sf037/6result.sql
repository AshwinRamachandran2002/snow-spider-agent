/*  Shortest straight-line (great-circle) distance, in miles,   
    between every “The Home Depot” location and its nearest   
    “Lowe’s Home Improvement” store                                  */

WITH home_depot AS (   -- every Home Depot POI with a lat/lon point
    SELECT  
        r."POI_ID"                                            AS "HD_POI_ID",
        ST_MAKEPOINT(a."LONGITUDE", a."LATITUDE")             AS "HD_POINT"
    FROM   US_REAL_ESTATE.CYBERSYN.POINT_OF_INTEREST_INDEX                p
    JOIN   US_REAL_ESTATE.CYBERSYN.POINT_OF_INTEREST_ADDRESSES_RELATIONSHIPS r
           ON p."POI_ID" = r."POI_ID"
    JOIN   US_REAL_ESTATE.CYBERSYN.US_ADDRESSES                            a
           ON r."ADDRESS_ID" = a."ADDRESS_ID"
    WHERE  p."POI_NAME" ILIKE '%Home%Depot%'                     -- Home Depot filter
), 
lowes AS (            -- every Lowe’s Home Improvement POI with a lat/lon point
    SELECT  
        r."POI_ID"                                            AS "LOWES_POI_ID",
        ST_MAKEPOINT(a."LONGITUDE", a."LATITUDE")             AS "LOWES_POINT"
    FROM   US_REAL_ESTATE.CYBERSYN.POINT_OF_INTEREST_INDEX                p
    JOIN   US_REAL_ESTATE.CYBERSYN.POINT_OF_INTEREST_ADDRESSES_RELATIONSHIPS r
           ON p."POI_ID" = r."POI_ID"
    JOIN   US_REAL_ESTATE.CYBERSYN.US_ADDRESSES                            a
           ON r."ADDRESS_ID" = a."ADDRESS_ID"
    WHERE  p."POI_NAME" ILIKE '%Lowe%'                        -- Lowe’s filter
      AND  p."POI_NAME" ILIKE '%Home%Improvement%'
)

SELECT  
    hd."HD_POI_ID"                                           AS "HOME_DEPOT_POI_ID",
    low."LOWES_POI_ID",
    ROUND( ST_DISTANCE(hd."HD_POINT", low."LOWES_POINT") / 1609 , 4 )   -- meters ➜ miles
          AS "MIN_DISTANCE_MILES"
FROM   home_depot hd
CROSS  JOIN lowes low
QUALIFY ROW_NUMBER() OVER (PARTITION BY hd."HD_POI_ID"
                           ORDER BY ST_DISTANCE(hd."HD_POINT", low."LOWES_POINT")) = 1
ORDER  BY "MIN_DISTANCE_MILES" NULLS LAST;