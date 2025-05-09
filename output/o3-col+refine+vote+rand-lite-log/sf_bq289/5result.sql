WITH philly AS (  -- Philadelphia city polygon
    SELECT TO_GEOGRAPHY("place_geom") AS geom
    FROM "GEO_OPENSTREETMAP_CENSUS_PLACES"."GEO_US_CENSUS_PLACES"."PLACES_PENNSYLVANIA"
    WHERE "place_name" = 'Philadelphia'
),
amenities AS (    -- amenity points inside Philadelphia
    SELECT
        ROW_NUMBER() OVER (ORDER BY p."geometry")        AS rid,   -- surrogate id
        TO_GEOGRAPHY(p."geometry")                       AS geog
    FROM "GEO_OPENSTREETMAP_CENSUS_PLACES"."GEO_OPENSTREETMAP"."PLANET_FEATURES_POINTS" p,
         LATERAL FLATTEN (INPUT => p."all_tags") f,
         philly
    WHERE f.value:"key"::STRING   = 'amenity'
      AND f.value:"value"::STRING IN ('library',
                                      'place_of_worship',
                                      'community_centre',
                                      'community_center')
      AND ST_CONTAINS(philly.geom, TO_GEOGRAPHY(p."geometry"))
)
SELECT MIN(ST_DISTANCE(a1.geog, a2.geog)) AS shortest_distance_meters
FROM amenities a1
JOIN amenities a2
  ON a1.rid < a2.rid;