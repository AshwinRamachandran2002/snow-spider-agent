WITH phila_boundary AS (
    SELECT ST_GEOGFROMWKB("place_geom") AS "poly"
    FROM "GEO_OPENSTREETMAP_CENSUS_PLACES"."GEO_US_CENSUS_PLACES"."PLACES_PENNSYLVANIA"
    WHERE "place_name" = 'Philadelphia'
    LIMIT 1
),
amenities AS (
    SELECT 
        pt."osm_id",
        ST_GEOGFROMWKB(pt."geometry") AS "geom"
    FROM "GEO_OPENSTREETMAP_CENSUS_PLACES"."GEO_OPENSTREETMAP"."PLANET_FEATURES_POINTS" pt,
         phila_boundary,
         LATERAL FLATTEN(INPUT => pt."all_tags") f
    WHERE f.value:"key"::STRING = 'amenity'
      AND f.value:"value"::STRING ILIKE ANY (
            'library',
            'place_of_worship',
            'community_centre',
            'community centre'
          )
      AND ST_CONTAINS((SELECT "poly" FROM phila_boundary),
                      ST_GEOGFROMWKB(pt."geometry"))
)
SELECT 
    TO_VARCHAR(a1."osm_id") || '-' || TO_VARCHAR(a2."osm_id") AS travel_coordinates,
    ROUND(ST_DISTANCE(a1."geom", a2."geom"), 4)              AS cumulative_travel_distance
FROM amenities a1
JOIN amenities a2
  ON a1."osm_id" < a2."osm_id"
ORDER BY cumulative_travel_distance
LIMIT 1;