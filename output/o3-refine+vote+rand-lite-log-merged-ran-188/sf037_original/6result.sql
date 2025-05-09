/* Nearest Lowe’s Home Improvement location for every The Home Depot store */
WITH poi_addresses AS (   -- POIs with resolved coordinates
    SELECT
        poi."POI_ID",
        poi."POI_NAME",
        addr."LONGITUDE",
        addr."LATITUDE"
    FROM US_REAL_ESTATE.CYBERSYN.POINT_OF_INTEREST_INDEX                   poi
    JOIN US_REAL_ESTATE.CYBERSYN.POINT_OF_INTEREST_ADDRESSES_RELATIONSHIPS rel
         ON poi."POI_ID" = rel."POI_ID"
    JOIN US_REAL_ESTATE.CYBERSYN.US_ADDRESSES                              addr
         ON rel."ADDRESS_ID" = addr."ADDRESS_ID"
    WHERE poi."POI_NAME" IN ('The Home Depot', 'Lowe''s Home Improvement')
          AND addr."LONGITUDE" IS NOT NULL
          AND addr."LATITUDE"  IS NOT NULL
),
home_depot AS (
    SELECT
        "POI_ID"                                          AS "HD_POI_ID",
        ST_MAKEPOINT("LONGITUDE", "LATITUDE")             AS "HD_GEOM"
    FROM poi_addresses
    WHERE "POI_NAME" = 'The Home Depot'
),
lowes AS (
    SELECT
        "POI_ID"                                          AS "LOWES_POI_ID",
        ST_MAKEPOINT("LONGITUDE", "LATITUDE")             AS "LOWES_GEOM"
    FROM poi_addresses
    WHERE "POI_NAME" = 'Lowe''s Home Improvement'
)

SELECT
    hd."HD_POI_ID"    AS "HOME_DEPOT_POI_ID",
    lw."LOWES_POI_ID" AS "NEAREST_LOWES_POI_ID",
    ROUND(
        ST_DISTANCE(hd."HD_GEOM", lw."LOWES_GEOM") / 1609.344,
        4
    )                 AS "DISTANCE_MILES"
FROM home_depot hd
CROSS JOIN lowes lw
QUALIFY ROW_NUMBER() OVER (
           PARTITION BY hd."HD_POI_ID"
           ORDER BY ST_DISTANCE(hd."HD_GEOM", lw."LOWES_GEOM")
       ) = 1
ORDER BY "HOME_DEPOT_POI_ID";