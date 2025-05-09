WITH phl AS (  -- Philadelphia city polygon
    SELECT 
        TO_GEOGRAPHY("place_geom") AS geog
    FROM GEO_OPENSTREETMAP_CENSUS_PLACES.GEO_US_CENSUS_PLACES.PLACES_PENNSYLVANIA
    WHERE "place_name" = 'Philadelphia'
    LIMIT 1
),
amenities AS (  -- libraries, places of worship, community centres inside Philadelphia
    SELECT
        ROW_NUMBER() OVER (ORDER BY p."geometry") AS id,
        TO_GEOGRAPHY(p."geometry")                AS geog
    FROM GEO_OPENSTREETMAP_CENSUS_PLACES.GEO_OPENSTREETMAP.PLANET_FEATURES_POINTS p,
         LATERAL FLATTEN(INPUT => TRY_PARSE_JSON(p."all_tags")) f,
         phl
    WHERE f.value:"key"::STRING = 'amenity'
      AND f.value:"value"::STRING IN ('library',
                                      'place_of_worship',
                                      'community_centre')
      AND ST_CONTAINS(phl.geog, TO_GEOGRAPHY(p."geometry"))
),
pair_distances AS (  -- pair-wise distances, keep distinct pairs only
    SELECT 
        ST_DISTANCE(a1.geog, a2.geog) AS distance_meters
    FROM amenities a1
    JOIN amenities a2 
      ON a1.id < a2.id
)
SELECT 
    MIN(distance_meters) AS "shortest_distance_meters"
FROM pair_distances;