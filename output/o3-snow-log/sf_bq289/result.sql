/*  shortest distance (meters) between any two amenities of interest
    located inside the Philadelphia (PA) city limits                     */

WITH philly AS (  ---------------------------------------------------------
  SELECT
      ST_GeogFromWKB("place_geom")                       AS "geom",
      ST_XMin(ST_GeogFromWKB("place_geom"))              AS "min_lon",
      ST_XMax(ST_GeogFromWKB("place_geom"))              AS "max_lon",
      ST_YMin(ST_GeogFromWKB("place_geom"))              AS "min_lat",
      ST_YMax(ST_GeogFromWKB("place_geom"))              AS "max_lat"
  FROM  GEO_OPENSTREETMAP_CENSUS_PLACES.GEO_US_CENSUS_PLACES.US_NATIONAL_PLACES
  WHERE LOWER("state_name") = 'pennsylvania'
    AND LOWER("place_name") = 'philadelphia'
  LIMIT 1
),

amenities AS (  ----------------------------------------------------------
  SELECT
      ROW_NUMBER() OVER (ORDER BY p."geometry")          AS "amenity_id",
      ST_GeogFromWKB(p."geometry")                       AS "geog"
  FROM  GEO_OPENSTREETMAP_CENSUS_PLACES.GEO_OPENSTREETMAP.PLANET_FEATURES_POINTS p,
        LATERAL FLATTEN(input => p."all_tags") tag,
        philly
  WHERE tag.value:"key"::string = 'amenity'
    AND LOWER(tag.value:"value"::string) IN
        ('library','place_of_worship','community_centre')
        -- quick bounding-box pre-filter
    AND ST_X(ST_GeogFromWKB(p."geometry"))
            BETWEEN philly."min_lon" AND philly."max_lon"
    AND ST_Y(ST_GeogFromWKB(p."geometry"))
            BETWEEN philly."min_lat" AND philly."max_lat"
        -- exact containment test
    AND ST_Contains(philly."geom", ST_GeogFromWKB(p."geometry"))
)

SELECT
    MIN( ST_Distance(a."geog", b."geog") )   AS "shortest_distance_meters"
FROM  amenities a
JOIN  amenities b
  ON   a."amenity_id" < b."amenity_id";