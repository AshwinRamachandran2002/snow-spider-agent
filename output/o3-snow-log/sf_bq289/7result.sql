WITH "PHILLY" AS (  -- polygon for the city of Philadelphia
    SELECT
        TO_GEOGRAPHY("place_geom") AS "geom"
    FROM GEO_OPENSTREETMAP_CENSUS_PLACES.GEO_US_CENSUS_PLACES.US_NATIONAL_PLACES
    WHERE LOWER("state_name")  = 'pennsylvania'
      AND LOWER("place_name")  = 'philadelphia'
), 

"AMENITIES" AS (    -- points of the three amenity types inside Philadelphia
    SELECT
        ROW_NUMBER() OVER (ORDER BY 1)           AS "amenity_id",
        TO_GEOGRAPHY(pfp."geometry")             AS "geom"
    FROM  GEO_OPENSTREETMAP_CENSUS_PLACES.GEO_OPENSTREETMAP.PLANET_FEATURES_POINTS  pfp,
          LATERAL FLATTEN ( INPUT => pfp."all_tags" ) tag,
          "PHILLY"
    WHERE tag.value:"key"::string               = 'amenity'
      AND LOWER(tag.value:"value"::string) IN ('library',
                                               'place_of_worship',
                                               'community_centre')
      AND ST_WITHIN( TO_GEOGRAPHY(pfp."geometry"), "PHILLY"."geom" )
)

SELECT 
    MIN( ST_DISTANCE(a."geom", b."geom") )   AS "shortest_distance_meters"
FROM  "AMENITIES" a
JOIN  "AMENITIES" b
  ON   a."amenity_id" < b."amenity_id";