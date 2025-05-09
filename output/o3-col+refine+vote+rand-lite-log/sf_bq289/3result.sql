/*  Shortest distance (in metres) between any two amenities
    (library, place_of_worship, community_centre / center)
    located inside the city limits of Philadelphia           */
WITH philly AS (   -------------------------------------------------- 1) Philadelphia polygon
    SELECT TO_GEOGRAPHY("place_geom") AS geom
    FROM   GEO_OPENSTREETMAP_CENSUS_PLACES.GEO_US_CENSUS_PLACES."PLACES_PENNSYLVANIA"
    WHERE  "place_name" = 'Philadelphia'
    LIMIT  1
),
amenities AS (      -------------------------------------------------- 2) Points of the three amenity types inside the polygon
    SELECT  ROW_NUMBER() OVER (ORDER BY 1)         AS amenity_id,
            TO_GEOGRAPHY(p."geometry")             AS geom
    FROM    GEO_OPENSTREETMAP_CENSUS_PLACES.GEO_OPENSTREETMAP."PLANET_FEATURES_POINTS" p,
            LATERAL FLATTEN (INPUT => p."all_tags") f,
            philly
    WHERE   f.value:"key"::STRING = 'amenity'
      AND ( f.value:"value"::STRING ILIKE '%library%'            -- library
         OR f.value:"value"::STRING ILIKE '%place%of%worship%'   -- place of worship
         OR f.value:"value"::STRING ILIKE '%community%centre%'   -- community centre (UK)
         OR f.value:"value"::STRING ILIKE '%community%center%' ) -- community center (US)
      AND   ST_CONTAINS(philly.geom , TO_GEOGRAPHY(p."geometry"))  -- inside Philadelphia
)
SELECT  ROUND( MIN( ST_DISTANCE(a.geom , b.geom) ), 4) AS shortest_distance_meters
FROM    amenities a
JOIN    amenities b
       ON a.amenity_id < b.amenity_id;