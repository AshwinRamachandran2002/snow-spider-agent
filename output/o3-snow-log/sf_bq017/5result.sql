/*  Five longest highway classes inside Denmark (relation whose tags contain wikidata = Q35)  */
WITH denmark AS (
    /* grab Denmark’s multipolygon geometry */
    SELECT  TO_GEOGRAPHY(r."geometry")  AS geom
    FROM    GEO_OPENSTREETMAP.GEO_OPENSTREETMAP."PLANET_RELATIONS"      r,
            LATERAL FLATTEN(input => r."all_tags")                      tag
    WHERE   tag.value:"key"::STRING   = 'wikidata'
      AND   tag.value:"value"::STRING = 'Q35'          -- Denmark
      AND   r."visible"                                    -- current version is visible
    LIMIT 1
),
highways AS (
    /* every OSM feature that carries a “highway” tag                          */
    /* (lines / multilines are most common but geometry is kept generic here)  */
    SELECT  tag.value:"value"::STRING            AS highway_type,
            TO_GEOGRAPHY(f."geometry")           AS geom
    FROM    GEO_OPENSTREETMAP.GEO_OPENSTREETMAP."PLANET_FEATURES"       f,
            LATERAL FLATTEN(input => f."all_tags")                       tag
    WHERE   tag.value:"key"::STRING = 'highway'
)

SELECT  h.highway_type,
        ROUND( SUM( ST_LENGTH(h.geom) ) / 1000 , 2)   AS total_length_km
FROM    highways h
JOIN    denmark  d
      ON ST_INTERSECTS(h.geom , d.geom)               -- keep features touching or inside DK
GROUP BY h.highway_type
ORDER BY total_length_km DESC NULLS LAST
LIMIT 5;