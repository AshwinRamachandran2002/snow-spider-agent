WITH home_depot_stores AS (
    SELECT
        p."POI_ID" AS "home_depot_poi_id",
        ST_GEOGFROMTEXT('POINT(' || a."LONGITUDE" || ' ' || a."LATITUDE" || ')') AS "hd_geog"
    FROM "US_REAL_ESTATE"."CYBERSYN"."POINT_OF_INTEREST_INDEX" p
    JOIN "US_REAL_ESTATE"."CYBERSYN"."POINT_OF_INTEREST_ADDRESSES_RELATIONSHIPS" r
        ON p."POI_ID" = r."POI_ID"
    JOIN "US_REAL_ESTATE"."CYBERSYN"."US_ADDRESSES" a
        ON r."ADDRESS_ID" = a."ADDRESS_ID"
    WHERE p."POI_NAME" ILIKE '%Home%Depot%'
),
lowes_stores AS (
    SELECT
        p."POI_ID" AS "lowes_poi_id",
        ST_GEOGFROMTEXT('POINT(' || a."LONGITUDE" || ' ' || a."LATITUDE" || ')') AS "lowes_geog"
    FROM "US_REAL_ESTATE"."CYBERSYN"."POINT_OF_INTEREST_INDEX" p
    JOIN "US_REAL_ESTATE"."CYBERSYN"."POINT_OF_INTEREST_ADDRESSES_RELATIONSHIPS" r
        ON p."POI_ID" = r."POI_ID"
    JOIN "US_REAL_ESTATE"."CYBERSYN"."US_ADDRESSES" a
        ON r."ADDRESS_ID" = a."ADDRESS_ID"
    WHERE p."POI_NAME" ILIKE '%Lowe%s%Home%Improvement%'
)
SELECT
    hd."home_depot_poi_id",
    ROUND(MIN(ST_DISTANCE(hd."hd_geog", lw."lowes_geog")) / 1609.344, 4) AS "distance_miles"
FROM home_depot_stores hd
CROSS JOIN lowes_stores lw
GROUP BY hd."home_depot_poi_id";