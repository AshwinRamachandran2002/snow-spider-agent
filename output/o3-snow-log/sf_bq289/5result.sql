/* Shortest distance (in meters) between any two amenities
   (library, place of worship, community centre) that lie
   inside the city limits of Philadelphia, Pennsylvania      */

WITH philly AS (        -- Philadelphia polygon
  SELECT
    TO_GEOGRAPHY("place_geom") AS geom
  FROM GEO_OPENSTREETMAP_CENSUS_PLACES.GEO_US_CENSUS_PLACES.US_NATIONAL_PLACES
  WHERE "state_name" = 'Pennsylvania'
    AND "place_name" = 'Philadelphia'
),

amenities AS (          -- Amenity points inside Philadelphia
  SELECT
    TO_GEOGRAPHY(p."geometry") AS geog,
    ROW_NUMBER() OVER (ORDER BY p."geometry") AS rid          -- simple surrogate id
  FROM  GEO_OPENSTREETMAP_CENSUS_PLACES.GEO_OPENSTREETMAP.PLANET_FEATURES_POINTS  p,
        LATERAL FLATTEN(INPUT => p."all_tags") f,             -- explode tag array
        philly
  WHERE f.value:"key"::string = 'amenity'
    AND LOWER(f.value:"value"::string) IN
        ('library','place_of_worship','community_centre')
    AND ST_CONTAINS(philly.geom , TO_GEOGRAPHY(p."geometry"))
)

SELECT
  MIN( ST_DISTANCE(a1.geog , a2.geog) )      AS shortest_distance_meters
FROM amenities a1
JOIN amenities a2
  ON a1.rid < a2.rid;        -- distinct unordered pairs