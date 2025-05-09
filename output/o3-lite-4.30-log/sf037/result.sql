WITH home_depot AS (
    /* All Home Depot locations with valid coordinates */
    SELECT
        poi_idx."POI_ID"                               AS "HD_POI_ID",
        ST_MAKEPOINT(addr."LONGITUDE", addr."LATITUDE") AS "HD_GEOG"
    FROM "US_REAL_ESTATE"."CYBERSYN"."POINT_OF_INTEREST_INDEX"                 poi_idx
    JOIN "US_REAL_ESTATE"."CYBERSYN"."POINT_OF_INTEREST_ADDRESSES_RELATIONSHIPS" rel
         ON poi_idx."POI_ID" = rel."POI_ID"
        AND rel."RELATIONSHIP_TYPE" = 'Overlaps'
    JOIN "US_REAL_ESTATE"."CYBERSYN"."US_ADDRESSES" addr
         ON rel."ADDRESS_ID" = addr."ADDRESS_ID"
    WHERE poi_idx."POI_NAME" ILIKE '%home depot%'
      AND addr."LATITUDE"  IS NOT NULL
      AND addr."LONGITUDE" IS NOT NULL
), 
lowes AS (
    /* All Lowe’s Home Improvement locations with valid coordinates */
    SELECT
        poi_idx."POI_ID"                               AS "LW_POI_ID",
        ST_MAKEPOINT(addr."LONGITUDE", addr."LATITUDE") AS "LW_GEOG"
    FROM "US_REAL_ESTATE"."CYBERSYN"."POINT_OF_INTEREST_INDEX"                 poi_idx
    JOIN "US_REAL_ESTATE"."CYBERSYN"."POINT_OF_INTEREST_ADDRESSES_RELATIONSHIPS" rel
         ON poi_idx."POI_ID" = rel."POI_ID"
        AND rel."RELATIONSHIP_TYPE" = 'Overlaps'
    JOIN "US_REAL_ESTATE"."CYBERSYN"."US_ADDRESSES" addr
         ON rel."ADDRESS_ID" = addr."ADDRESS_ID"
    WHERE poi_idx."POI_NAME" ILIKE '%lowe%home%improvement%'
      AND addr."LATITUDE"  IS NOT NULL
      AND addr."LONGITUDE" IS NOT NULL
)
SELECT
    hd."HD_POI_ID"                         AS home_depot_poi_id,
    ST_ASWKT(hd."HD_GEOG")                 AS home_depot_coordinates,
    lw."LW_POI_ID"                         AS nearest_lowes_poi_id,
    ST_ASWKT(lw."LW_GEOG")                 AS lowes_coordinates,
    ROUND(ST_DISTANCE(hd."HD_GEOG", lw."LW_GEOG") / 1609, 4)
                                          AS straight_line_distance_miles
FROM home_depot hd
JOIN lowes lw ON 1 = 1      /* cartesian join to evaluate every pair */
QUALIFY ROW_NUMBER() OVER (
            PARTITION BY hd."HD_POI_ID"
            ORDER BY ST_DISTANCE(hd."HD_GEOG", lw."LW_GEOG")
       ) = 1
ORDER BY hd."HD_POI_ID";