/* Shortest straight-line distance (miles) from each “The Home Depot” store
   to its nearest “Lowe’s Home Improvement” location */

WITH home_depot AS (
    SELECT
        h."POI_ID"                                      AS "HD_POI_ID",
        h."POI_NAME"                                    AS "HD_NAME",
        ST_MAKEPOINT(u."LONGITUDE", u."LATITUDE")       AS "HD_POINT"
    FROM "US_REAL_ESTATE"."CYBERSYN"."POINT_OF_INTEREST_INDEX"                h
    JOIN "US_REAL_ESTATE"."CYBERSYN"."POINT_OF_INTEREST_ADDRESSES_RELATIONSHIPS" r
      ON h."POI_ID" = r."POI_ID"
    JOIN "US_REAL_ESTATE"."CYBERSYN"."US_ADDRESSES"                          u
      ON r."ADDRESS_ID" = u."ADDRESS_ID"
    WHERE h."POI_NAME" ILIKE '%the home depot%'          -- Home Depot stores
), 
lowes AS (
    SELECT
        l."POI_ID"                                      AS "LW_POI_ID",
        l."POI_NAME"                                    AS "LW_NAME",
        ST_MAKEPOINT(u."LONGITUDE", u."LATITUDE")       AS "LW_POINT"
    FROM "US_REAL_ESTATE"."CYBERSYN"."POINT_OF_INTEREST_INDEX"                l
    JOIN "US_REAL_ESTATE"."CYBERSYN"."POINT_OF_INTEREST_ADDRESSES_RELATIONSHIPS" r
      ON l."POI_ID" = r."POI_ID"
    JOIN "US_REAL_ESTATE"."CYBERSYN"."US_ADDRESSES"                          u
      ON r."ADDRESS_ID" = u."ADDRESS_ID"
    WHERE l."POI_NAME" ILIKE 'lowe''s home improvement%' -- Lowe’s stores
)

SELECT
    hd."HD_POI_ID"            AS "HOME_DEPOT_POI_ID",
    hd."HD_NAME"              AS "HOME_DEPOT_NAME",
    lw."LW_POI_ID"            AS "NEAREST_LOWES_POI_ID",
    lw."LW_NAME"              AS "NEAREST_LOWES_NAME",
    ST_DISTANCE(hd."HD_POINT", lw."LW_POINT") / 1609    AS "DISTANCE_MILES"
FROM home_depot hd
JOIN lowes lw ON TRUE
QUALIFY ROW_NUMBER() OVER (
            PARTITION BY hd."HD_POI_ID"
            ORDER BY ST_DISTANCE(hd."HD_POINT", lw."LW_POINT")
       ) = 1
ORDER BY "DISTANCE_MILES";