/* 5 longest highway types inside Denmark (wikidata = Q35) */
WITH denmark AS (   -- Denmark multipolygon from relation tagged wikidata=Q35
    SELECT TO_GEOGRAPHY(r."geometry") AS geom
    FROM   GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_RELATIONS r,
           LATERAL FLATTEN( INPUT => r."all_tags" ) tag
    WHERE  r."visible" = TRUE
      AND  r."geometry" IS NOT NULL
      AND  tag.value:"key"::STRING   = 'wikidata'
      AND  tag.value:"value"::STRING = 'Q35'
    ORDER BY ST_AREA( TO_GEOGRAPHY(r."geometry") ) DESC NULLS LAST
    LIMIT 1
),
highway_feats AS (  -- every feature carrying a highway=* tag
    SELECT  TO_GEOGRAPHY(pf."geometry")            AS geo,
            tag.value:"value"::STRING              AS highway_type
    FROM    GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES pf,
            LATERAL FLATTEN( INPUT => pf."all_tags" ) tag
    WHERE   tag.value:"key"::STRING = 'highway'
      AND   pf."geometry" IS NOT NULL
)
SELECT   h.highway_type,
         SUM( ST_LENGTH(h.geo) ) AS total_length_meters
FROM     highway_feats h,
         denmark d
WHERE    ST_INTERSECTS(h.geo, d.geom)
GROUP BY h.highway_type
ORDER BY total_length_meters DESC NULLS LAST
LIMIT 5;