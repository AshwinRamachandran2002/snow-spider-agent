WITH
/* Philadelphia city polygon (Pennsylvania)                                   */
philly AS (
    SELECT
        TO_GEOGRAPHY("place_geom") AS geom
    FROM GEO_OPENSTREETMAP_CENSUS_PLACES.GEO_US_CENSUS_PLACES.US_NATIONAL_PLACES
    WHERE LOWER("state_name") = 'pennsylvania'
      AND LOWER("place_name") LIKE 'philadelphia%'
    LIMIT 1
),
/* Amenity points inside Philadelphia – library, place of worship, community centre */
amenities AS (
    SELECT
        ROW_NUMBER() OVER (ORDER BY p."geometry")    AS id,
        TO_GEOGRAPHY(p."geometry")                   AS geog
    FROM GEO_OPENSTREETMAP_CENSUS_PLACES.GEO_OPENSTREETMAP.PLANET_FEATURES_POINTS p,
         LATERAL FLATTEN(INPUT => p."all_tags") tag,
         philly ph                                  -- bring the polygon into scope
    WHERE tag.value:"key"::STRING = 'amenity'
      AND LOWER(tag.value:"value"::STRING) IN ('library',
                                               'place_of_worship',
                                               'community_centre',
                                               'community_center')
      AND ST_CONTAINS(ph.geom, TO_GEOGRAPHY(p."geometry"))
)
/* Pair-wise distances and minimum (in metres, GEOGRAPHY default)             */
SELECT
    MIN(ST_DISTANCE(a.geog, b.geog)) AS "shortest_distance_meters"
FROM amenities a
JOIN amenities b
  ON a.id < b.id;