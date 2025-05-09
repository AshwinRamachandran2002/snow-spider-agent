-- Five longest highway types inside Denmark (wikidata = 'Q35')
WITH denmark AS (   -- Denmark national boundary as GEOGRAPHY
    SELECT ST_GEOGFROMWKB(r."geometry") AS geog
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP."PLANET_RELATIONS" r,
         LATERAL FLATTEN(input => r."all_tags") f
    WHERE f.value:"key"::STRING   = 'wikidata'
      AND f.value:"value"::STRING = 'Q35'
    LIMIT 1
), highway_segments AS (   -- each highway feature wholly inside Denmark
    SELECT
        f.value:"value"::STRING            AS highway_type,
        ST_LENGTH(g.geog)                  AS segment_len_m
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP."PLANET_FEATURES" t
         , LATERAL FLATTEN(input => t."all_tags") f
         , LATERAL ( SELECT ST_GEOGFROMWKB(t."geometry")      AS geog,
                            ST_ASWKT(ST_GEOGFROMWKB(t."geometry")) AS wkt ) g
         , denmark d
    WHERE f.value:"key"::STRING = 'highway'                           -- highway-tagged features
      AND (g.wkt LIKE 'LINESTRING%' OR g.wkt LIKE 'MULTILINESTRING%') -- keep linear geometries
      AND ST_COVERS(d.geog, g.geog)                                   -- inside Denmark
)
SELECT
    highway_type,
    SUM(segment_len_m) AS total_length_m
FROM highway_segments
GROUP BY highway_type
ORDER BY total_length_m DESC NULLS LAST
LIMIT 5;