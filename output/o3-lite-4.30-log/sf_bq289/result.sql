WITH philly AS (                         -- Philadelphia city polygon
    SELECT TO_GEOGRAPHY("place_geom") AS geom
    FROM GEO_OPENSTREETMAP_CENSUS_PLACES.GEO_US_CENSUS_PLACES.PLACES_PENNSYLVANIA
    WHERE "place_name" = 'Philadelphia'
    LIMIT 1
),
amenities AS (                           -- amenity points inside Philadelphia
    SELECT
        pt."osm_id",
        TO_GEOGRAPHY(pt."geometry") AS geom_pt
    FROM GEO_OPENSTREETMAP_CENSUS_PLACES.GEO_OPENSTREETMAP.PLANET_FEATURES_POINTS pt,
         LATERAL FLATTEN(input => pt."all_tags") f,
         philly
    WHERE f.value:"key"::STRING = 'amenity'
      AND f.value:"value"::STRING IN ('library','place_of_worship','community_centre','community_center')
      AND ST_CONTAINS(philly.geom, TO_GEOGRAPHY(pt."geometry"))
)
SELECT ROUND(
         MIN(ST_DISTANCE(a1.geom_pt, a2.geom_pt))
       , 4) AS "shortest_distance_meters"
FROM amenities a1
JOIN amenities a2
  ON a1."osm_id" < a2."osm_id";