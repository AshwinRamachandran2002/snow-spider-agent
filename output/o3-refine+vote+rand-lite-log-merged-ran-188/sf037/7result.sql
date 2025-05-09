/* --------------------------------------------------------------------
   Nearest-neighbor distance (in miles) from each “The Home Depot” store
   to the closest “Lowe’s Home Improvement” location
---------------------------------------------------------------------*/
WITH home_depot AS (   -- all Home Depot stores with coordinates
    SELECT DISTINCT
           r."POI_ID"                             AS "home_depot_poi_id",
           ST_MAKEPOINT(a."LONGITUDE", a."LATITUDE") AS "hd_point"
    FROM US_REAL_ESTATE.CYBERSYN.POINT_OF_INTEREST_INDEX                  p
    JOIN US_REAL_ESTATE.CYBERSYN.POINT_OF_INTEREST_ADDRESSES_RELATIONSHIPS r
         ON p."POI_ID" = r."POI_ID"
    JOIN US_REAL_ESTATE.CYBERSYN.US_ADDRESSES                             a
         ON a."ADDRESS_ID" = r."ADDRESS_ID"
    WHERE p."POI_NAME" ILIKE '%Home%Depot%'         -- identify Home Depot
),
lowes AS (         -- all Lowe’s stores with coordinates
    SELECT DISTINCT
           r."POI_ID"                             AS "lowes_poi_id",
           ST_MAKEPOINT(a."LONGITUDE", a."LATITUDE") AS "lowes_point"
    FROM US_REAL_ESTATE.CYBERSYN.POINT_OF_INTEREST_INDEX                  p
    JOIN US_REAL_ESTATE.CYBERSYN.POINT_OF_INTEREST_ADDRESSES_RELATIONSHIPS r
         ON p."POI_ID" = r."POI_ID"
    JOIN US_REAL_ESTATE.CYBERSYN.US_ADDRESSES                             a
         ON a."ADDRESS_ID" = r."ADDRESS_ID"
    WHERE p."POI_NAME" ILIKE '%Lowe%s Home%Improvement%'  -- identify Lowe’s
)

SELECT
       h."home_depot_poi_id",
       l."lowes_poi_id"                                            AS "nearest_lowes_poi_id",
       ST_DISTANCE(h."hd_point", l."lowes_point") / 1609           AS "distance_miles"
FROM   home_depot h
JOIN   lowes     l
       ON TRUE  -- Cartesian join to test every Lowe’s against every Home Depot
QUALIFY ROW_NUMBER() OVER (
            PARTITION BY h."home_depot_poi_id"
            ORDER BY ST_DISTANCE(h."hd_point", l."lowes_point")
        ) = 1     -- keep only the closest Lowe’s for each Home Depot
ORDER  BY "distance_miles" NULLS LAST;