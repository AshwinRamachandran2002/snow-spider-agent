WITH philadelphia AS (
    SELECT "place_geom"
    FROM GEO_OPENSTREETMAP_CENSUS_PLACES.GEO_US_CENSUS_PLACES.PLACES_PENNSYLVANIA
    WHERE "place_name" = 'Philadelphia'
    LIMIT 1
),
amenities AS (
    SELECT p."osm_id",
           p."geometry"
    FROM GEO_OPENSTREETMAP_CENSUS_PLACES.GEO_OPENSTREETMAP.PLANET_FEATURES_POINTS p,
         LATERAL FLATTEN(INPUT => p."all_tags") f,
         philadelphia ph
    WHERE f.value:"key"::STRING = 'amenity'
      AND f.value:"value"::STRING IN ('library', 'place_of_worship', 'community_centre')
      AND ST_CONTAINS(
            TO_GEOGRAPHY(ph."place_geom"),
            TO_GEOGRAPHY(p."geometry")
          )
)
SELECT ROUND(
         MIN(
           ST_DISTANCE(
             TO_GEOGRAPHY(a."geometry"),
             TO_GEOGRAPHY(b."geometry")
           )
         ), 4
       ) AS "shortest_distance_meters"
FROM amenities a
JOIN amenities b
  ON a."osm_id" < b."osm_id";