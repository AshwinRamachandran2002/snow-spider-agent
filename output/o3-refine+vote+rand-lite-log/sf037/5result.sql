WITH home_depot AS (   -- every The Home Depot location with coordinates
    SELECT  
        hd."POI_ID"                        AS "HD_POI_ID",
        rel."ADDRESS_ID"                   AS "HD_ADDRESS_ID",
        addr."LATITUDE"                    AS "HD_LAT",
        addr."LONGITUDE"                   AS "HD_LON",
        addr."CITY"                        AS "HD_CITY",
        addr."STATE"                       AS "HD_STATE"
    FROM US_REAL_ESTATE.CYBERSYN."POINT_OF_INTEREST_INDEX"                     hd
    JOIN US_REAL_ESTATE.CYBERSYN."POINT_OF_INTEREST_ADDRESSES_RELATIONSHIPS"   rel
         ON hd."POI_ID" = rel."POI_ID"
    JOIN US_REAL_ESTATE.CYBERSYN."US_ADDRESSES"                                addr
         ON rel."ADDRESS_ID" = addr."ADDRESS_ID"
    WHERE hd."POI_NAME" = 'The Home Depot'
      AND addr."LATITUDE"  IS NOT NULL
      AND addr."LONGITUDE" IS NOT NULL
),
lowes AS (          -- every Lowe's Home Improvement location with coordinates
    SELECT  
        lw."POI_ID"                       AS "LOWES_POI_ID",
        rel."ADDRESS_ID"                  AS "LOWES_ADDRESS_ID",
        addr."LATITUDE"                   AS "LOWES_LAT",
        addr."LONGITUDE"                  AS "LOWES_LON"
    FROM US_REAL_ESTATE.CYBERSYN."POINT_OF_INTEREST_INDEX"                     lw
    JOIN US_REAL_ESTATE.CYBERSYN."POINT_OF_INTEREST_ADDRESSES_RELATIONSHIPS"   rel
         ON lw."POI_ID" = rel."POI_ID"
    JOIN US_REAL_ESTATE.CYBERSYN."US_ADDRESSES"                                addr
         ON rel."ADDRESS_ID" = addr."ADDRESS_ID"
    WHERE lw."POI_NAME" = 'Lowe''s Home Improvement'
      AND addr."LATITUDE"  IS NOT NULL
      AND addr."LONGITUDE" IS NOT NULL
)

SELECT
    hd."HD_POI_ID",
    hd."HD_ADDRESS_ID",
    hd."HD_CITY",
    hd."HD_STATE",
    l."LOWES_POI_ID",
    l."LOWES_ADDRESS_ID",
    ROUND(
        ST_DISTANCE(
            ST_MAKEPOINT(hd."HD_LON",   hd."HD_LAT"),   -- Home Depot point
            ST_MAKEPOINT(l."LOWES_LON", l."LOWES_LAT")  -- Lowe’s point
        ) / 1609,                                       -- meters → miles
        4
    )                                   AS "DISTANCE_MILES"
FROM home_depot hd
CROSS JOIN lowes l
QUALIFY ROW_NUMBER() OVER (
            PARTITION BY hd."HD_POI_ID"
            ORDER BY "DISTANCE_MILES"
       ) = 1        -- keep only the nearest Lowe’s for each Home Depot
ORDER BY "DISTANCE_MILES";