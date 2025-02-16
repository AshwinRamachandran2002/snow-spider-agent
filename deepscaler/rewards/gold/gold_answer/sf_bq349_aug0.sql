-- Task: Identify the OpenStreetMap ID ("osm_id") from the "PLANET_FEATURES" table that corresponds to an administrative boundary represented as a 'multipolygons' feature with a "boundary" tag value of 'administrative' in its "all_tags". For each such boundary, calculate the total number of 'amenity'-tagged Points of Interest (POIs) from the "PLANET_NODES" table—specifically where "all_tags" contains 'amenity' as a key—that are located within the boundary. Then, find the "osm_id" whose total POI count is closest to the median POI count across all these administrative boundaries.

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
),
    
poi_counts AS (
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
),
    
median_value AS (
    SELECT 
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY total_pois) AS median_pois
    FROM poi_counts
),
    
closest_to_median AS (
    SELECT
        "osm_id",
        total_pois,
        ABS(total_pois - (SELECT median_pois FROM median_value)) AS diff_from_median
    FROM poi_counts
)
    
SELECT
    "osm_id"
FROM closest_to_median
ORDER BY diff_from_median
LIMIT 1;