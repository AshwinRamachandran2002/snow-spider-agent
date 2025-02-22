-- Task: For each administrative boundary represented as a multipolygon in the planet features table, compute the total number of 'amenity'-tagged Points of Interest (POIs) in the planet nodes table that are located within it. Return the first 100 results.
WITH bounding_area AS (
    SELECT 
        "osm_id",
        "geometry" AS geometry,
        ST_AREA(ST_GEOGRAPHYFROMWKB("geometry")) AS area
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES,
    LATERAL FLATTEN(INPUT => PLANET_FEATURES."all_tags") AS "tag"
    WHERE 
        "feature_type" = 'multipolygons'
        AND "tag".value:"key" = 'boundary'
        AND "tag".value:"value" = 'administrative'
),

poi AS (
    SELECT 
        nodes."id" AS poi_id,
        nodes."geometry" AS poi_geometry,
        tags.value:"value" AS poitype
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_NODES AS nodes,
    LATERAL FLATTEN(INPUT => nodes."all_tags") AS tags
    WHERE tags.value:"key" = 'amenity'
)

SELECT
    ba."osm_id",
    COUNT(poi.poi_id) AS total_pois
FROM bounding_area ba
JOIN poi
ON ST_DWITHIN(
    ST_GEOGRAPHYFROMWKB(ba.geometry), 
    ST_GEOGRAPHYFROMWKB(poi.poi_geometry), 
    0.0
)
GROUP BY ba."osm_id"
LIMIT 100;