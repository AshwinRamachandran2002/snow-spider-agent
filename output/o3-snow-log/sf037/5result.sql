/*  For every “The Home Depot” store that has usable coordinates,
    return the single closest “Lowe’s Home Improvement” store and
    the straight-line distance in miles.                                         */

WITH
/* -------------------------------------------------------------------------- */
/* 1) Home Depot locations with coordinates                                    */
home_depot AS (
    SELECT
        p."POI_ID"          AS "HD_POI_ID",
        a."LATITUDE",
        a."LONGITUDE"
    FROM US_REAL_ESTATE.CYBERSYN."POINT_OF_INTEREST_INDEX"               p
    JOIN US_REAL_ESTATE.CYBERSYN."POINT_OF_INTEREST_ADDRESSES_RELATIONSHIPS" r
           ON p."POI_ID" = r."POI_ID"
    JOIN US_REAL_ESTATE.CYBERSYN."US_ADDRESSES"                         a
           ON a."ADDRESS_ID" = r."ADDRESS_ID"
    WHERE p."POI_NAME" ILIKE '%Home%Depot%'        -- The Home Depot stores
      AND a."LATITUDE"  IS NOT NULL
),

/* -------------------------------------------------------------------------- */
/* 2) Lowe’s locations with coordinates                                       */
lowes AS (
    SELECT
        p."POI_ID"          AS "LOWES_POI_ID",
        a."LATITUDE",
        a."LONGITUDE"
    FROM US_REAL_ESTATE.CYBERSYN."POINT_OF_INTEREST_INDEX"               p
    JOIN US_REAL_ESTATE.CYBERSYN."POINT_OF_INTEREST_ADDRESSES_RELATIONSHIPS" r
           ON p."POI_ID" = r."POI_ID"
    JOIN US_REAL_ESTATE.CYBERSYN."US_ADDRESSES"                         a
           ON a."ADDRESS_ID" = r."ADDRESS_ID"
    WHERE p."POI_NAME" ILIKE '%Lowe%s%Home%Improvement%' -- Lowe’s stores
      AND a."LATITUDE"  IS NOT NULL
)

/* -------------------------------------------------------------------------- */
/* 3) Pair every Home Depot to every Lowe’s, keep the nearest Lowe’s per HD   */
SELECT
    hd."HD_POI_ID"        AS "HOME_DEPOT_POI_ID",
    l."LOWES_POI_ID"      AS "LOWES_POI_ID",
    ST_DISTANCE(
        ST_MAKEPOINT(hd."LONGITUDE", hd."LATITUDE"),   -- Home Depot coords
        ST_MAKEPOINT(l."LONGITUDE",  l."LATITUDE")     -- Lowe’s coords
    ) / 1609                                           AS "MILES_TO_LOWES"   -- meters → miles
FROM home_depot hd
JOIN lowes     l
  ON 1 = 1                                           -- Cartesian join for all pairs
QUALIFY ROW_NUMBER() OVER (
            PARTITION BY hd."HD_POI_ID"
            ORDER BY ST_DISTANCE(
                       ST_MAKEPOINT(hd."LONGITUDE", hd."LATITUDE"),
                       ST_MAKEPOINT(l."LONGITUDE",  l."LATITUDE")
                     )
       ) = 1;