-- Task: Retrieve the top five highway types based on their total lengths within the geographic boundaries of Denmark (specified by the multipolygon with Wikidata ID 'Q35') from the "PLANET_FEATURES" table. The computation should consider features of type 'lines' that are tagged with 'highway', sum their lengths grouped by highway type, and present the results ordered by descending total length.
WITH bounding_area AS (
    SELECT "geometry" AS geometry
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES,
    LATERAL FLATTEN(INPUT => "PLANET_FEATURES"."all_tags") AS "tag"
    WHERE "feature_type" = 'multipolygons'
      AND "tag".value:"key" = 'wikidata'
      AND "tag".value:"value" = 'Q35'
),

highway_info AS (
    SELECT 
        SUM(ST_LENGTH(
                ST_GEOGRAPHYFROMWKB("PLANET_FEATURES"."geometry")
            )
        ) AS highway_length,
        "tag".value:"value" AS highway_type
    FROM 
        GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES AS "PLANET_FEATURES",
        bounding_area
    CROSS JOIN LATERAL FLATTEN(INPUT => "PLANET_FEATURES"."all_tags") AS "tag"
    WHERE "tag".value:"key" = 'highway'
      AND "feature_type" = 'lines'
      AND ST_DWITHIN(
            ST_GEOGFROMWKB("PLANET_FEATURES"."geometry"), 
            ST_GEOGFROMWKB(bounding_area.geometry),
            0.0
        ) 
    GROUP BY highway_type
)

SELECT 
  REPLACE(highway_type, '"', '') AS highway_type
FROM
  highway_info
ORDER BY 
  highway_length DESC
LIMIT 5;