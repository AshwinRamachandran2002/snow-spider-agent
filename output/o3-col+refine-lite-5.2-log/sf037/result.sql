/*   nearest‑neighbor distance (miles) between every “The Home Depot” and
     its closest “Lowe’s Home Improvement” store                     */

WITH home_depot AS (   -- all Home Depot POIs with coordinates
    SELECT
        h."POI_ID",
        a."LONGITUDE",
        a."LATITUDE"
    FROM US_REAL_ESTATE.CYBERSYN."POINT_OF_INTEREST_INDEX"                h
    JOIN US_REAL_ESTATE.CYBERSYN."POINT_OF_INTEREST_ADDRESSES_RELATIONSHIPS" r
          ON h."POI_ID" = r."POI_ID"
    JOIN US_REAL_ESTATE.CYBERSYN."US_ADDRESSES"                           a
          ON r."ADDRESS_ID" = a."ADDRESS_ID"
    WHERE h."POI_NAME" ILIKE '%The%Home%Depot%'           -- Home Depot only
),

lowes AS (            -- all Lowe’s POIs with coordinates
    SELECT
        l."POI_ID",
        a."LONGITUDE",
        a."LATITUDE"
    FROM US_REAL_ESTATE.CYBERSYN."POINT_OF_INTEREST_INDEX"                l
    JOIN US_REAL_ESTATE.CYBERSYN."POINT_OF_INTEREST_ADDRESSES_RELATIONSHIPS" r
          ON l."POI_ID" = r."POI_ID"
    JOIN US_REAL_ESTATE.CYBERSYN."US_ADDRESSES"                           a
          ON r."ADDRESS_ID" = a."ADDRESS_ID"
    WHERE l."POI_NAME" ILIKE '%Lowe''s%Home%Improvement%' -- Lowe’s only
)

SELECT
    hd."POI_ID"                                                AS "HDEPOT_POI_ID",
    lo."POI_ID"                                                AS "LOWES_POI_ID",
    ST_DISTANCE(
        ST_MAKEPOINT(hd."LONGITUDE", hd."LATITUDE"),
        ST_MAKEPOINT(lo."LONGITUDE", lo."LATITUDE")
    ) / 1609                                                   AS "DISTANCE_MILES"
FROM home_depot hd
JOIN lowes lo                    -- Cartesian join → distance to every Lowe’s
     ON TRUE
QUALIFY ROW_NUMBER() OVER (       -- keep only the closest Lowe’s per HD store
           PARTITION BY hd."POI_ID"
           ORDER BY ST_DISTANCE(
                     ST_MAKEPOINT(hd."LONGITUDE", hd."LATITUDE"),
                     ST_MAKEPOINT(lo."LONGITUDE", lo."LATITUDE")
           )
       ) = 1
ORDER BY hd."POI_ID";