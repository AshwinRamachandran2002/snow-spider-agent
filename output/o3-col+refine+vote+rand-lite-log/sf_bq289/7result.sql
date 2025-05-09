/* Shortest distance (in meters) between any two libraries, places of worship, or community centres
   located inside the Philadelphia municipal polygon.                                    */

WITH philly_poly AS (      -- Philadelphia city limits
    SELECT ST_GEOGFROMWKB("place_geom") AS "geom"
    FROM GEO_OPENSTREETMAP_CENSUS_PLACES.GEO_US_CENSUS_PLACES.PLACES_PENNSYLVANIA
    WHERE "place_name" = 'Philadelphia'
),

philly_amenities AS (      -- Points whose tags match the three amenity types and fall inside the polygon
    SELECT
        ROW_NUMBER() OVER (ORDER BY 1)                    AS "amenity_id",
        ST_GEOGFROMWKB(pfp."geometry")                    AS "geom"
    FROM GEO_OPENSTREETMAP_CENSUS_PLACES.GEO_OPENSTREETMAP.PLANET_FEATURES_POINTS pfp,
         philly_poly pp
    WHERE ST_CONTAINS(
              pp."geom",
              ST_GEOGFROMWKB(pfp."geometry")
          )
      AND pfp."all_tags" ILIKE '%amenity%'
      AND (
              pfp."all_tags" ILIKE '%library%' OR
              pfp."all_tags" ILIKE '%place%of%worship%' OR
              pfp."all_tags" ILIKE '%community%cent%'        -- matches both “centre” & “center”
          )
),

pairs AS (                 -- All unique amenity-to-amenity pairs
    SELECT
        ST_DISTANCE(a."geom", b."geom") AS "dist_m"
    FROM philly_amenities a
    JOIN philly_amenities b
      ON a."amenity_id" < b."amenity_id"
)

SELECT ROUND( MIN("dist_m"), 4 ) AS "shortest_distance_meters"
FROM pairs;