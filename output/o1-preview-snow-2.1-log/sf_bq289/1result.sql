WITH philadelphia_boundary AS (
  SELECT "place_geom"
  FROM "GEO_OPENSTREETMAP_CENSUS_PLACES"."GEO_US_CENSUS_PLACES"."PLACES_PENNSYLVANIA"
  WHERE "place_name" = 'Philadelphia'
),
amenities AS (
  SELECT 
    t."osm_id", 
    t."geometry", 
    f.value:"value"::STRING AS "amenity_type"
  FROM
    "GEO_OPENSTREETMAP_CENSUS_PLACES"."GEO_OPENSTREETMAP"."PLANET_FEATURES_POINTS" t,
    LATERAL FLATTEN(input => t."all_tags") f
  WHERE
    f.value:"key" = 'amenity' AND 
    f.value:"value" IN ('library', 'place_of_worship', 'community_centre')
),
amenities_in_philadelphia AS (
  SELECT 
    a."osm_id", 
    a."geometry",
    a."amenity_type"
  FROM 
    amenities a
    CROSS JOIN philadelphia_boundary pb
  WHERE
    TO_GEOGRAPHY(a."geometry") IS NOT NULL
    AND ST_CONTAINS(TO_GEOGRAPHY(pb."place_geom"), TO_GEOGRAPHY(a."geometry"))
)
SELECT 
  ROUND(MIN(distance_in_meters), 4) AS shortest_distance_meters
FROM (
  SELECT 
    a1."osm_id" AS osm_id1,
    a2."osm_id" AS osm_id2,
    ST_DISTANCE(TO_GEOGRAPHY(a1."geometry"), TO_GEOGRAPHY(a2."geometry")) AS distance_in_meters
  FROM
    amenities_in_philadelphia a1
    INNER JOIN amenities_in_philadelphia a2
      ON a1."osm_id" < a2."osm_id"
) distances;