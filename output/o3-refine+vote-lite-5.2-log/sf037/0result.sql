WITH
-- All “The Home Depot” locations with coordinates
HOME_DEPOT AS (
    SELECT
        poi."POI_ID"                          AS "HD_POI_ID",
        addr."LATITUDE"                       AS "HD_LAT",
        addr."LONGITUDE"                      AS "HD_LON"
    FROM US_REAL_ESTATE.CYBERSYN.POINT_OF_INTEREST_INDEX               poi
    JOIN US_REAL_ESTATE.CYBERSYN.POINT_OF_INTEREST_ADDRESSES_RELATIONSHIPS par
        ON par."POI_ID" = poi."POI_ID"
    JOIN US_REAL_ESTATE.CYBERSYN.US_ADDRESSES                          addr
        ON addr."ADDRESS_ID" = par."ADDRESS_ID"
    WHERE poi."POI_NAME" = 'The Home Depot'
      AND addr."LATITUDE"  IS NOT NULL
      AND addr."LONGITUDE" IS NOT NULL
),

-- All “Lowe’s Home Improvement” locations with coordinates
LOWES AS (
    SELECT
        poi."POI_ID"                          AS "LOWES_POI_ID",
        addr."LATITUDE"                       AS "LOWES_LAT",
        addr."LONGITUDE"                      AS "LOWES_LON"
    FROM US_REAL_ESTATE.CYBERSYN.POINT_OF_INTEREST_INDEX               poi
    JOIN US_REAL_ESTATE.CYBERSYN.POINT_OF_INTEREST_ADDRESSES_RELATIONSHIPS par
        ON par."POI_ID" = poi."POI_ID"
    JOIN US_REAL_ESTATE.CYBERSYN.US_ADDRESSES                          addr
        ON addr."ADDRESS_ID" = par."ADDRESS_ID"
    WHERE poi."POI_NAME" = 'Lowe''s Home Improvement'
      AND addr."LATITUDE"  IS NOT NULL
      AND addr."LONGITUDE" IS NOT NULL
)

SELECT
    hd."HD_POI_ID"                                                              AS "HOME_DEPOT_POI_ID",
    low."LOWES_POI_ID"                                                          AS "NEAREST_LOWES_POI_ID",
    ROUND(
        ST_DISTANCE(
            ST_MAKEPOINT(hd."HD_LON",   hd."HD_LAT"),
            ST_MAKEPOINT(low."LOWES_LON", low."LOWES_LAT")
        ) / 1609 , 4)                                                           AS "DISTANCE_MILES"
FROM HOME_DEPOT hd
CROSS JOIN LOWES low
QUALIFY ROW_NUMBER() OVER (PARTITION BY hd."HD_POI_ID"
                           ORDER BY ST_DISTANCE(
                                       ST_MAKEPOINT(hd."HD_LON", hd."HD_LAT"),
                                       ST_MAKEPOINT(low."LOWES_LON", low."LOWES_LAT")
                                   )
                          ) = 1;