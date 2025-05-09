WITH philly AS (   -- Philadelphia city polygon
    SELECT TO_GEOGRAPHY("place_geom") AS geom
    FROM GEO_OPENSTREETMAP_CENSUS_PLACES.GEO_US_CENSUS_PLACES."PLACES_PENNSYLVANIA"
    WHERE "place_name" = 'Philadelphia'
), philly_amenities AS (   -- all libraries, places of worship, community centres inside Philadelphia
    SELECT
        ROW_NUMBER() OVER (ORDER BY p."geometry")        AS amenity_id,
        TO_GEOGRAPHY(p."geometry")                       AS g
    FROM GEO_OPENSTREETMAP_CENSUS_PLACES.GEO_OPENSTREETMAP."PLANET_FEATURES_POINTS" p
         ,LATERAL FLATTEN(INPUT => p."all_tags") f
         ,philly
    WHERE f.value:"key"::STRING = 'amenity'
      AND LOWER(f.value:"value"::STRING) IN ('library','place_of_worship','community_centre')
      AND ST_CONTAINS(philly.geom, TO_GEOGRAPHY(p."geometry"))
)
SELECT
    MIN( ST_DISTANCE(a.g, b.g) ) AS "shortest_distance_meters"
FROM philly_amenities a
JOIN philly_amenities b
  ON a.amenity_id < b.amenity_id;