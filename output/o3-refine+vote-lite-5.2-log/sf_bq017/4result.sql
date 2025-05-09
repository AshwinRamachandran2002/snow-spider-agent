/* Five longest highway types inside Denmark (Wikidata = Q35) */
WITH "DENMARK" AS (   -- Denmark multipolygon (latest version)
    SELECT 
        TO_GEOGRAPHY("geometry") AS geom
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_RELATIONS r
         , LATERAL FLATTEN(input => r."all_tags") t
    WHERE t.value:key   = 'wikidata'
      AND t.value:value = 'Q35'
      AND r."geometry" IS NOT NULL
    ORDER BY r."version" DESC NULLS LAST   -- take newest geometry
    LIMIT 1
),
"HIGHWAY_SEGMENTS" AS (  -- highway geometries clipped to Denmark
    SELECT
        tag.value:value::string              AS highway_type,
        ST_INTERSECTION(
            TO_GEOGRAPHY(pf."geometry"),     -- original segment
            (SELECT geom FROM "DENMARK")     -- Denmark boundary
        )                                    AS geom_part
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES pf
         , LATERAL FLATTEN(input => pf."all_tags") tag
    WHERE pf."feature_type" = 'lines'            -- linear features only
      AND tag.value:key = 'highway'              -- must have highway tag
      AND pf."geometry" IS NOT NULL
      AND ST_INTERSECTS(                         -- preliminary spatial filter
            TO_GEOGRAPHY(pf."geometry"),
            (SELECT geom FROM "DENMARK")
          )
      AND tag.value:value IS NOT NULL
),
"LENGTHS" AS (           -- length (metres) for each clipped segment
    SELECT
        highway_type,
        ST_LENGTH(geom_part) AS seg_len_m
    FROM "HIGHWAY_SEGMENTS"
    WHERE geom_part IS NOT NULL
)
SELECT
    highway_type,
    ROUND(SUM(seg_len_m), 2) AS total_length_m
FROM "LENGTHS"
GROUP BY highway_type
ORDER BY total_length_m DESC NULLS LAST, highway_type
LIMIT 5;