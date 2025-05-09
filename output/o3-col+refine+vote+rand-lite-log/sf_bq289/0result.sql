WITH philly_polygon AS (
    SELECT 
        TO_GEOGRAPHY("place_geom") AS "geom"
    FROM GEO_OPENSTREETMAP_CENSUS_PLACES.GEO_US_CENSUS_PLACES.PLACES_PENNSYLVANIA
    WHERE "place_name" = 'Philadelphia'
),

philly_amenities AS (
    SELECT
        ROW_NUMBER() OVER (ORDER BY p."geometry") AS "id",
        TO_GEOGRAPHY(p."geometry")               AS "geom"
    FROM GEO_OPENSTREETMAP_CENSUS_PLACES.GEO_OPENSTREETMAP.PLANET_FEATURES_POINTS p,
         philly_polygon poly,
         LATERAL FLATTEN(input => p."all_tags") f
    WHERE ST_CONTAINS(poly."geom", TO_GEOGRAPHY(p."geometry"))
      AND f.value:"key"::STRING  = 'amenity'
      AND f.value:"value"::STRING IN ('library', 'place_of_worship', 'community_centre')
)

SELECT 
    MIN( ST_DISTANCE(a."geom", b."geom") ) AS "shortest_distance_meters"
FROM philly_amenities a
JOIN philly_amenities b
  ON a."id" < b."id"
WHERE ST_DISTANCE(a."geom", b."geom") > 0;