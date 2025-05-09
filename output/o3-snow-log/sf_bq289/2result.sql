WITH philly AS (   -- Philadelphia city boundary
    SELECT
        TO_GEOGRAPHY("place_geom") AS geom
    FROM GEO_OPENSTREETMAP_CENSUS_PLACES.GEO_US_CENSUS_PLACES.US_NATIONAL_PLACES
    WHERE LOWER("place_name")  = 'philadelphia'
      AND LOWER("state_name")  = 'pennsylvania'
    LIMIT 1
),

amenities AS (     -- libraries, places of worship, community centres inside the city
    SELECT
        TO_GEOGRAPHY(p."geometry")                         AS geom,
        ROW_NUMBER() OVER (ORDER BY p."geometry")          AS rid     -- unique id
    FROM GEO_OPENSTREETMAP_CENSUS_PLACES.GEO_OPENSTREETMAP.PLANET_FEATURES_POINTS  p
         , LATERAL FLATTEN(INPUT => p."all_tags") f
         , philly
    WHERE f.value:"key"::string = 'amenity'
      AND LOWER(f.value:"value"::string) IN ( 'library',
                                              'place_of_worship',
                                              'community_center',
                                              'community_centre')
      AND ST_CONTAINS(philly.geom , TO_GEOGRAPHY(p."geometry"))
),

pair_distances AS (   -- distance for every unique amenity pair
    SELECT
        a.rid,
        b.rid,
        ST_DISTANCE(a.geom , b.geom) AS dist_meters
    FROM amenities a
    JOIN amenities b
      ON a.rid < b.rid          -- avoid self-pairs & duplicate pairs
)

-- shortest distance between any two selected amenities
SELECT MIN(dist_meters) AS shortest_distance_meters
FROM pair_distances;