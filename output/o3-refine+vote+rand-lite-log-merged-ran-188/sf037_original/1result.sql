/*  nearest Lowe’s location (and miles apart) for every The Home Depot store */
WITH
-- all Home Depot stores with coordinates
home_depot AS (
    SELECT
        p."POI_ID"              AS "HD_POI_ID",
        a."LATITUDE"            AS "HD_LAT",
        a."LONGITUDE"           AS "HD_LON"
    FROM US_REAL_ESTATE.CYBERSYN.POINT_OF_INTEREST_INDEX p
    JOIN US_REAL_ESTATE.CYBERSYN.POINT_OF_INTEREST_ADDRESSES_RELATIONSHIPS pa
          ON p."POI_ID" = pa."POI_ID"
    JOIN US_REAL_ESTATE.CYBERSYN.US_ADDRESSES a
          ON pa."ADDRESS_ID" = a."ADDRESS_ID"
    WHERE p."POI_NAME" = 'The Home Depot'
      AND a."LATITUDE"  IS NOT NULL
      AND a."LONGITUDE" IS NOT NULL
),
-- all Lowe’s Home Improvement stores with coordinates
lowes AS (
    SELECT
        p."POI_ID"              AS "LOWES_POI_ID",
        a."LATITUDE"            AS "LOWES_LAT",
        a."LONGITUDE"           AS "LOWES_LON"
    FROM US_REAL_ESTATE.CYBERSYN.POINT_OF_INTEREST_INDEX p
    JOIN US_REAL_ESTATE.CYBERSYN.POINT_OF_INTEREST_ADDRESSES_RELATIONSHIPS pa
          ON p."POI_ID" = pa."POI_ID"
    JOIN US_REAL_ESTATE.CYBERSYN.US_ADDRESSES a
          ON pa."ADDRESS_ID" = a."ADDRESS_ID"
    WHERE p."POI_NAME" = 'Lowe''s Home Improvement'
      AND a."LATITUDE"  IS NOT NULL
      AND a."LONGITUDE" IS NOT NULL
)

SELECT
    hd."HD_POI_ID"             AS "HOME_DEPOT_POI_ID",
    l."LOWES_POI_ID"           AS "NEAREST_LOWES_POI_ID",
    -- distance in miles (ST_DISTANCE returns meters for GEOGRAPHY)
    ST_DISTANCE(
        ST_MAKEPOINT(hd."HD_LON",    hd."HD_LAT"),
        ST_MAKEPOINT(l."LOWES_LON",  l."LOWES_LAT")
    ) / 1609                AS "DISTANCE_MILES"
FROM home_depot hd
CROSS JOIN lowes l
QUALIFY
    ROW_NUMBER() OVER (
        PARTITION BY hd."HD_POI_ID"
        ORDER BY
            ST_DISTANCE(
                ST_MAKEPOINT(hd."HD_LON",    hd."HD_LAT"),
                ST_MAKEPOINT(l."LOWES_LON",  l."LOWES_LAT")
            )
    ) = 1;