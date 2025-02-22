-- Task: Count the number of amenities (libraries, places of worship, or community centers) located within Philadelphia.
WITH philadelphia AS (
    SELECT 
        * 
    FROM 
        GEO_OPENSTREETMAP_CENSUS_PLACES.GEO_US_CENSUS_PLACES.PLACES_PENNSYLVANIA
    WHERE 
        "place_name" = 'Philadelphia'
),
amenities AS (
    SELECT 
        features.*, 
        tags.value:"value" AS amenity
    FROM 
        GEO_OPENSTREETMAP_CENSUS_PLACES.GEO_OPENSTREETMAP.PLANET_FEATURES_POINTS AS features
        CROSS JOIN philadelphia
        , LATERAL FLATTEN(input => features."all_tags") AS tags
    WHERE 
        ST_CONTAINS(ST_GEOGFROMWKB(philadelphia."place_geom"), ST_GEOGFROMWKB(features."geometry"))
        AND tags.value:"key" = 'amenity' 
        AND tags.value:"value" IN ('library', 'place_of_worship', 'community_centre')
)
SELECT COUNT(*) AS "Amenities Count"
FROM amenities;