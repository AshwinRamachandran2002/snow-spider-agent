WITH "HOME_DEPOT" AS (   -- every The Home Depot with coordinates
    SELECT 
        poi."POI_ID",
        poi."POI_NAME",
        addr."LATITUDE",
        addr."LONGITUDE"
    FROM US_REAL_ESTATE.CYBERSYN.POINT_OF_INTEREST_INDEX                     AS poi
    JOIN US_REAL_ESTATE.CYBERSYN.POINT_OF_INTEREST_ADDRESSES_RELATIONSHIPS   AS rel
          ON poi."POI_ID" = rel."POI_ID"
    JOIN US_REAL_ESTATE.CYBERSYN.US_ADDRESSES                                AS addr
          ON rel."ADDRESS_ID" = addr."ADDRESS_ID"
    WHERE poi."POI_NAME" = 'The Home Depot'
      AND addr."LATITUDE"  IS NOT NULL
      AND addr."LONGITUDE" IS NOT NULL
), 
"LOWES" AS (            -- every Lowe's Home Improvement with coordinates
    SELECT 
        poi."POI_ID",
        poi."POI_NAME",
        addr."LATITUDE",
        addr."LONGITUDE"
    FROM US_REAL_ESTATE.CYBERSYN.POINT_OF_INTEREST_INDEX                     AS poi
    JOIN US_REAL_ESTATE.CYBERSYN.POINT_OF_INTEREST_ADDRESSES_RELATIONSHIPS   AS rel
          ON poi."POI_ID" = rel."POI_ID"
    JOIN US_REAL_ESTATE.CYBERSYN.US_ADDRESSES                                AS addr
          ON rel."ADDRESS_ID" = addr."ADDRESS_ID"
    WHERE poi."POI_NAME" = 'Lowe''s Home Improvement'
      AND addr."LATITUDE"  IS NOT NULL
      AND addr."LONGITUDE" IS NOT NULL
)

SELECT
    hd."POI_ID"                                       AS "HOME_DEPOT_POI_ID",
    hd."POI_NAME"                                     AS "HOME_DEPOT_NAME",
    lw."POI_ID"                                       AS "LOWES_POI_ID",
    lw."POI_NAME"                                     AS "LOWES_NAME",
    ST_DISTANCE(
        ST_MAKEPOINT(hd."LONGITUDE", hd."LATITUDE"),  -- meters
        ST_MAKEPOINT(lw."LONGITUDE", lw."LATITUDE")
    ) / 1609                                          AS "DISTANCE_MILES"
FROM "HOME_DEPOT" hd
CROSS JOIN "LOWES" lw
QUALIFY ROW_NUMBER() OVER (
            PARTITION BY hd."POI_ID"
            ORDER BY ST_DISTANCE(
                        ST_MAKEPOINT(hd."LONGITUDE", hd."LATITUDE"),
                        ST_MAKEPOINT(lw."LONGITUDE", lw."LATITUDE")
                     )
        ) = 1
ORDER BY "DISTANCE_MILES";