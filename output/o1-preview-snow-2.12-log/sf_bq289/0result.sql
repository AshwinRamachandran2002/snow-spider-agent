WITH philadelphia AS (
    SELECT ST_GEOGFROMWKB("place_geom") AS "geom"
    FROM GEO_OPENSTREETMAP_CENSUS_PLACES.GEO_US_CENSUS_PLACES.PLACES_PENNSYLVANIA
    WHERE "place_name" = 'Philadelphia'
),
amenities AS (
    SELECT a."osm_id", a."geom"
    FROM (
        SELECT
            t."osm_id",
            ST_GEOGFROMWKB(t."geometry") AS "geom"
        FROM GEO_OPENSTREETMAP_CENSUS_PLACES.GEO_OPENSTREETMAP.PLANET_FEATURES_POINTS t,
             LATERAL FLATTEN(input => t."all_tags") f
        WHERE f.VALUE:"key"::STRING = 'amenity'
          AND f.VALUE:"value"::STRING IN ('library', 'place_of_worship', 'community_centre')
    ) a,
    philadelphia p
    WHERE ST_CONTAINS(p."geom", a."geom")
)
SELECT ROUND(MIN(ST_DISTANCE(a1."geom", a2."geom")), 4) AS shortest_distance_meters
FROM amenities a1
JOIN amenities a2 ON a1."osm_id" < a2."osm_id";