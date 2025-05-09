WITH home_depot_stores AS (
    SELECT hd_poi."POI_ID" AS "Home_Depot_POI_ID",
           addr."LATITUDE" AS "HD_LATITUDE",
           addr."LONGITUDE" AS "HD_LONGITUDE"
    FROM US_REAL_ESTATE.CYBERSYN."POINT_OF_INTEREST_INDEX" hd_poi
    JOIN US_REAL_ESTATE.CYBERSYN."POINT_OF_INTEREST_ADDRESSES_RELATIONSHIPS" hd_addr_rel
        ON hd_poi."POI_ID" = hd_addr_rel."POI_ID"
    JOIN US_REAL_ESTATE.CYBERSYN."US_ADDRESSES" addr
        ON hd_addr_rel."ADDRESS_ID" = addr."ADDRESS_ID"
    WHERE hd_poi."POI_NAME" ILIKE '%Home Depot%'
      AND addr."LATITUDE" IS NOT NULL
      AND addr."LONGITUDE" IS NOT NULL
),
lowes_stores AS (
    SELECT lw_poi."POI_ID" AS "Lowes_POI_ID",
           addr."LATITUDE" AS "LW_LATITUDE",
           addr."LONGITUDE" AS "LW_LONGITUDE"
    FROM US_REAL_ESTATE.CYBERSYN."POINT_OF_INTEREST_INDEX" lw_poi
    JOIN US_REAL_ESTATE.CYBERSYN."POINT_OF_INTEREST_ADDRESSES_RELATIONSHIPS" lw_addr_rel
        ON lw_poi."POI_ID" = lw_addr_rel."POI_ID"
    JOIN US_REAL_ESTATE.CYBERSYN."US_ADDRESSES" addr
        ON lw_addr_rel."ADDRESS_ID" = addr."ADDRESS_ID"
    WHERE lw_poi."POI_NAME" ILIKE '%Lowe''s Home Improvement%'
      AND addr."LATITUDE" IS NOT NULL
      AND addr."LONGITUDE" IS NOT NULL
),
distances AS (
    SELECT
        hd."Home_Depot_POI_ID",
        lw."Lowes_POI_ID",
        ROUND(
            ST_DISTANCE(
                ST_MAKEPOINT(hd."HD_LONGITUDE", hd."HD_LATITUDE"),
                ST_MAKEPOINT(lw."LW_LONGITUDE", lw."LW_LATITUDE")
            ) / 1609.344,
            4
        ) AS "Distance_miles"
    FROM home_depot_stores hd
    CROSS JOIN lowes_stores lw
),
nearest_lowes AS (
    SELECT
        d.*,
        ROW_NUMBER() OVER (PARTITION BY d."Home_Depot_POI_ID" ORDER BY d."Distance_miles") AS rn
    FROM distances d
)
SELECT
    "Home_Depot_POI_ID",
    "Lowes_POI_ID" AS "Nearest_Lowes_POI_ID",
    "Distance_miles"
FROM nearest_lowes
WHERE rn = 1;