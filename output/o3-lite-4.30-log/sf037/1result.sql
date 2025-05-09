WITH home_depot AS (   -- every Home Depot store with coordinates
    SELECT DISTINCT
           p."POI_ID"     AS hd_poi,
           a."LATITUDE"   AS hd_lat,
           a."LONGITUDE"  AS hd_lon
    FROM "US_REAL_ESTATE"."CYBERSYN"."POINT_OF_INTEREST_INDEX"                   p
    JOIN "US_REAL_ESTATE"."CYBERSYN"."POINT_OF_INTEREST_ADDRESSES_RELATIONSHIPS" r
         ON p."POI_ID" = r."POI_ID"
    JOIN "US_REAL_ESTATE"."CYBERSYN"."US_ADDRESSES"                              a
         ON r."ADDRESS_ID" = a."ADDRESS_ID"
    WHERE p."POI_NAME" ILIKE '%home%depot%'
      AND a."LATITUDE"  IS NOT NULL
      AND a."LONGITUDE" IS NOT NULL
),
lowes AS (          -- every Lowe’s Home Improvement store with coordinates
    SELECT DISTINCT
           p."POI_ID"     AS lw_poi,
           a."LATITUDE"   AS lw_lat,
           a."LONGITUDE"  AS lw_lon
    FROM "US_REAL_ESTATE"."CYBERSYN"."POINT_OF_INTEREST_INDEX"                   p
    JOIN "US_REAL_ESTATE"."CYBERSYN"."POINT_OF_INTEREST_ADDRESSES_RELATIONSHIPS" r
         ON p."POI_ID" = r."POI_ID"
    JOIN "US_REAL_ESTATE"."CYBERSYN"."US_ADDRESSES"                              a
         ON r."ADDRESS_ID" = a."ADDRESS_ID"
    WHERE p."POI_NAME" ILIKE '%lowe%home%improvement%'
      AND a."LATITUDE"  IS NOT NULL
      AND a."LONGITUDE" IS NOT NULL
)

SELECT
    hd.hd_poi                                                                                   AS home_depot_poi_id,
    TO_VARCHAR(ROUND(hd.hd_lat,4))||','||TO_VARCHAR(ROUND(hd.hd_lon,4))                         AS home_depot_coordinates,
    lw.lw_poi                                                                                   AS nearest_lowes_poi_id,
    TO_VARCHAR(ROUND(lw.lw_lat,4))||','||TO_VARCHAR(ROUND(lw.lw_lon,4))                         AS lowes_coordinates,
    ROUND(
        ST_DISTANCE(
            ST_MAKEPOINT(hd.hd_lon, hd.hd_lat),
            ST_MAKEPOINT(lw.lw_lon, lw.lw_lat)
        ) / 1609 , 4
    )                                                                                           AS straight_line_distance_miles
FROM   home_depot hd
CROSS  JOIN lowes   lw
QUALIFY ROW_NUMBER() OVER (PARTITION BY hd.hd_poi
                           ORDER BY straight_line_distance_miles) = 1
ORDER  BY straight_line_distance_miles;