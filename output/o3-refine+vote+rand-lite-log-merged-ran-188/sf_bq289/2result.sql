/*  Shortest distance (in meters) between any two amenities 
    (library, place of worship, community centre / center) that lie
    inside the municipal boundary of Philadelphia, Pennsylvania       */

WITH philly AS (           -- Polygon for the City of Philadelphia
    SELECT TO_GEOGRAPHY("place_geom") AS "geom"
    FROM   GEO_OPENSTREETMAP_CENSUS_PLACES.GEO_US_CENSUS_PLACES.PLACES_PENNSYLVANIA
    WHERE  "place_name" = 'Philadelphia'       -- avoids “New Philadelphia”
    LIMIT  1
),

amenities AS (             -- All requested amenity-points inside Philadelphia
    SELECT
           ROW_NUMBER() OVER (ORDER BY 1)              AS "id",
           TO_GEOGRAPHY(p."geometry")                  AS "geom"
    FROM   GEO_OPENSTREETMAP_CENSUS_PLACES.GEO_OPENSTREETMAP.PLANET_FEATURES_POINTS p
    CROSS  JOIN LATERAL FLATTEN(input => p."all_tags") f
    CROSS  JOIN philly
    WHERE  f.value:"key"::STRING   =  'amenity'
      AND  LOWER(f.value:"value"::STRING) IN
           ('library','place_of_worship','community_centre','community_center')
      AND  ST_CONTAINS(philly."geom", TO_GEOGRAPHY(p."geometry"))
)

SELECT MIN( ST_DISTANCE(a."geom", b."geom") ) AS "shortest_distance_meters"
FROM   amenities a
JOIN   amenities b
       ON a."id" < b."id";