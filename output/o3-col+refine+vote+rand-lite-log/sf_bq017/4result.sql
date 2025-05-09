/*  Five longest highway categories (by total length in metres) that lie inside
    the Denmark multipolygon (wikidata = 'Q35').
*/
WITH denmark AS (   --------------------------------------------------- 1. Denmark boundary
    SELECT
        TO_GEOGRAPHY(r."geometry") AS geog
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_RELATIONS      r,
         LATERAL FLATTEN (INPUT => r."all_tags")                   tag
    WHERE  tag.value:"key"::STRING   = 'wikidata'
      AND  tag.value:"value"::STRING = 'Q35'
    LIMIT 1
),
highways AS (       --------------------------------------------------- 2. All highway features
    SELECT
        tag.value:"value"::STRING              AS highway_type,
        TO_GEOGRAPHY(pf."geometry")            AS geog_line
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES        pf,
         LATERAL FLATTEN (INPUT => pf."all_tags")                   tag
    WHERE tag.value:"key"::STRING = 'highway'            -- keep only highway-tagged features
      AND pf."geometry" IS NOT NULL                      -- geometry must exist
      AND pf."feature_type" IN (                         -- linear features only
              'linestrings','multilinestrings','lines','line')
)
SELECT
    highway_type,
    ROUND( SUM( ST_LENGTH( ST_INTERSECTION(h.geog_line , d.geog) ) ), 2 ) AS total_length_m
FROM highways h
CROSS JOIN denmark d
WHERE ST_INTERSECTS(h.geog_line , d.geog)                -- ensure they touch Denmark
GROUP BY highway_type
ORDER BY total_length_m DESC NULLS LAST
LIMIT 5;