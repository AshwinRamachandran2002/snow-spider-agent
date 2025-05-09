/* Shortest straight-line (great-circle) distance, in miles,
   from every “The Home Depot” store to the closest “Lowe’s Home Improvement” */

WITH home_depot AS (
    SELECT
        p."POI_ID"                                            AS "HOME_DEPOT_POI_ID",
        ST_MAKEPOINT(a."LONGITUDE", a."LATITUDE")             AS "HD_POINT"
    FROM   US_REAL_ESTATE.CYBERSYN."POINT_OF_INTEREST_INDEX"               p
    JOIN   US_REAL_ESTATE.CYBERSYN."POINT_OF_INTEREST_ADDRESSES_RELATIONSHIPS" r
           ON p."POI_ID" = r."POI_ID"
    JOIN   US_REAL_ESTATE.CYBERSYN."US_ADDRESSES"                           a
           ON r."ADDRESS_ID" = a."ADDRESS_ID"
    WHERE  p."POI_NAME" ILIKE '%home depot%'        -- captures “The Home Depot” & variants
),

lowes AS (
    SELECT
        p."POI_ID"                                            AS "LOWES_POI_ID",
        ST_MAKEPOINT(a."LONGITUDE", a."LATITUDE")             AS "LOWES_POINT"
    FROM   US_REAL_ESTATE.CYBERSYN."POINT_OF_INTEREST_INDEX"               p
    JOIN   US_REAL_ESTATE.CYBERSYN."POINT_OF_INTEREST_ADDRESSES_RELATIONSHIPS" r
           ON p."POI_ID" = r."POI_ID"
    JOIN   US_REAL_ESTATE.CYBERSYN."US_ADDRESSES"                           a
           ON r."ADDRESS_ID" = a."ADDRESS_ID"
    WHERE  p."POI_NAME" ILIKE '%lowe%home%improve%'         -- captures “Lowe’s Home Improvement”
)

SELECT
    h."HOME_DEPOT_POI_ID",
    l."LOWES_POI_ID"                                         AS "NEAREST_LOWES_POI_ID",
    ROUND( ST_DISTANCE(h."HD_POINT", l."LOWES_POINT") / 1609 , 4) 
                                                             AS "DISTANCE_MILES"
FROM   home_depot h
CROSS  JOIN lowes  l
QUALIFY ROW_NUMBER() OVER (PARTITION BY h."HOME_DEPOT_POI_ID"
                           ORDER BY ST_DISTANCE(h."HD_POINT", l."LOWES_POINT")) = 1
ORDER  BY "DISTANCE_MILES" NULLS LAST;