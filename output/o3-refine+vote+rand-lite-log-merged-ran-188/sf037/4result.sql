/*  Shortest straight-line (great-circle) distance – in miles – between every
    “The Home Depot” store and its nearest “Lowe’s Home Improvement” location   */

WITH
-- 1.  All Home Depot POIs with lat / lon
"HD" AS (
    SELECT
        r."POI_ID"                     AS "HD_POI_ID",
        a."LATITUDE",
        a."LONGITUDE"
    FROM   US_REAL_ESTATE.CYBERSYN.POINT_OF_INTEREST_INDEX                   p
    JOIN   US_REAL_ESTATE.CYBERSYN.POINT_OF_INTEREST_ADDRESSES_RELATIONSHIPS r
           ON p."POI_ID" = r."POI_ID"
    JOIN   US_REAL_ESTATE.CYBERSYN.US_ADDRESSES                              a
           ON a."ADDRESS_ID" = r."ADDRESS_ID"
    WHERE  p."POI_NAME" ILIKE '%home%depot%'          -- matches “The Home Depot”
),

-- 2.  All Lowe’s POIs with lat / lon
"LOWES" AS (
    SELECT
        r."POI_ID"                     AS "LOWES_POI_ID",
        a."LATITUDE",
        a."LONGITUDE"
    FROM   US_REAL_ESTATE.CYBERSYN.POINT_OF_INTEREST_INDEX                   p
    JOIN   US_REAL_ESTATE.CYBERSYN.POINT_OF_INTEREST_ADDRESSES_RELATIONSHIPS r
           ON p."POI_ID" = r."POI_ID"
    JOIN   US_REAL_ESTATE.CYBERSYN.US_ADDRESSES                              a
           ON a."ADDRESS_ID" = r."ADDRESS_ID"
    WHERE  p."POI_NAME" ILIKE '%lowe%home%improvement%' -- matches “Lowe’s Home Improvement”
)

-- 3.  Pair every HD with every Lowe’s, compute distance, keep closest Lowe’s
SELECT
    hd."HD_POI_ID"        AS "HOME_DEPOT_POI_ID",
    lo."LOWES_POI_ID"     AS "NEAREST_LOWES_POI_ID",
    ST_DISTANCE(
        ST_MAKEPOINT(hd."LONGITUDE", hd."LATITUDE"),
        ST_MAKEPOINT(lo."LONGITUDE", lo."LATITUDE")
    ) / 1609              AS "DISTANCE_MILES"          -- convert meters → miles
FROM   "HD"   hd
JOIN   "LOWES" lo
QUALIFY ROW_NUMBER() OVER (
           PARTITION BY hd."HD_POI_ID"
           ORDER BY ST_DISTANCE(
                       ST_MAKEPOINT(hd."LONGITUDE", hd."LATITUDE"),
                       ST_MAKEPOINT(lo."LONGITUDE", lo."LATITUDE")
                    )
       ) = 1                   -- keep only the nearest Lowe’s per Home Depot
ORDER BY "DISTANCE_MILES" ;     -- optional: closest pairs listed first