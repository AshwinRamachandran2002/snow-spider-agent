-- Task: Compute the total length of each highway type within the multipolygon boundary of Denmark (as defined by Wikidata ID 'Q35') through planet features, displaying up to 100 results.

WITH bounding_area AS (
    SELECT "geometry" AS geometry
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES,
    LATERAL FLATTEN(INPUT => planet_features."all_tags") AS "tag"
    WHERE "feature_type" = 'multipolygons'
      AND "tag".value:"key" = 'wikidata'
      AND "tag".value:"value" = 'Q35'
),

highway_info AS (
    SELECT 
        SUM(ST_LENGTH(
                ST_GEOGRAPHYFROMWKB(planet_features."geometry")
            )
        ) AS highway_length,
        "tag".value:"value" AS highway_type
    FROM 
        GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES AS planet_features,
        bounding_area
    CROSS JOIN LATERAL FLATTEN(INPUT => planet_features."all_tags") AS "tag"
    WHERE "tag".value:"key" = 'highway'
      AND "feature_type" = 'lines'
      AND ST_DWITHIN(
          ST_GEOGFROMWKB(planet_features."geometry"), 
          ST_GEOGFROMWKB(bounding_area.geometry),
          0.0
      ) 
    GROUP BY highway_type
)

SELECT 
  REPLACE(highway_type, '"', '') AS highway_type,
  highway_length
FROM
  highway_info
LIMIT 100;