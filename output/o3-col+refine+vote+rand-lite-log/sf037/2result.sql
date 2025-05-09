/*  Shortest straight-line distance (in miles) from every “The Home Depot” POI
    to its nearest “Lowe’s Home Improvement” POI                       */

WITH hd AS (   -- all Home Depot POIs with geometries
    SELECT
        p."POI_ID"                                           AS "hd_poi_id",
        ST_MAKEPOINT(a."LONGITUDE", a."LATITUDE")            AS "hd_geom"
    FROM   US_REAL_ESTATE.CYBERSYN.POINT_OF_INTEREST_INDEX                  p
    JOIN   US_REAL_ESTATE.CYBERSYN.POINT_OF_INTEREST_ADDRESSES_RELATIONSHIPS r
           ON r."POI_ID" = p."POI_ID"
    JOIN   US_REAL_ESTATE.CYBERSYN.US_ADDRESSES                              a
           ON a."ADDRESS_ID" = r."ADDRESS_ID"
    WHERE  p."POI_NAME" ILIKE '%home%depot%'                -- Home Depot
),
lw AS (   -- all Lowe’s Home Improvement POIs with geometries
    SELECT
        p."POI_ID"                                           AS "lowes_poi_id",
        ST_MAKEPOINT(a."LONGITUDE", a."LATITUDE")            AS "lowes_geom"
    FROM   US_REAL_ESTATE.CYBERSYN.POINT_OF_INTEREST_INDEX                  p
    JOIN   US_REAL_ESTATE.CYBERSYN.POINT_OF_INTEREST_ADDRESSES_RELATIONSHIPS r
           ON r."POI_ID" = p."POI_ID"
    JOIN   US_REAL_ESTATE.CYBERSYN.US_ADDRESSES                              a
           ON a."ADDRESS_ID" = r."ADDRESS_ID"
    WHERE  p."POI_NAME" ILIKE '%lowe%s%improvement%'         -- Lowe’s
)

SELECT
    hd."hd_poi_id",
    lw."lowes_poi_id",
    ST_DISTANCE(hd."hd_geom", lw."lowes_geom") / 1609       AS "distance_miles"
FROM   hd
CROSS  JOIN lw
QUALIFY ROW_NUMBER() OVER (PARTITION BY hd."hd_poi_id"
                           ORDER BY "distance_miles") = 1   -- nearest Lowe’s
ORDER  BY "distance_miles";                                 -- optional