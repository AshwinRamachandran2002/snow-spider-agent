WITH philly_geom AS (
    SELECT TO_GEOGRAPHY("place_geom") AS philly_geom
    FROM GEO_OPENSTREETMAP_CENSUS_PLACES.GEO_US_CENSUS_PLACES.PLACES_PENNSYLVANIA
    WHERE "place_name" = 'Philadelphia'
),
amenities AS (
    SELECT t."osm_id", TO_GEOGRAPHY(t."geometry") AS geometry
    FROM GEO_OPENSTREETMAP_CENSUS_PLACES.GEO_OPENSTREETMAP.PLANET_FEATURES_POINTS t,
         LATERAL FLATTEN(input => t."all_tags") f
    WHERE f.value:"key"::STRING = 'amenity'
      AND f.value:"value"::STRING IN ('library', 'place_of_worship', 'community_centre')
      AND ST_CONTAINS(
          (SELECT philly_geom FROM philly_geom),
          TO_GEOGRAPHY(t."geometry"))
),
pairwise_distances AS (
    SELECT
        a1."osm_id" AS osm_id1,
        a2."osm_id" AS osm_id2,
        ST_DISTANCE(a1.geometry, a2.geometry) AS distance_meters
    FROM amenities a1
    JOIN amenities a2 ON a1."osm_id" < a2."osm_id"
)
SELECT
    ROUND(MIN(distance_meters), 4) AS shortest_distance_meters
FROM pairwise_distances;