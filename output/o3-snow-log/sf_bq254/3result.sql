/*  Task:  
    – find the envelope (bounding box) of the multipolygon whose wikidata = ‘Q191’ (Estonia);  
    – take every other multipolygon that INTERSECTS that envelope and that has NO own wikidata tag;  
    – count how many point-features fall inside each such multipolygon;  
    – return the two multipolygons with the highest counts together with their (optional) “name”. */

WITH q191_env AS (                                        -- 1.  envelope of Estonia (wikidata Q191)
    SELECT ST_ENVELOPE( TO_GEOGRAPHY(pf."geometry") ) AS env
    FROM   GEO_OPENSTREETMAP.GEO_OPENSTREETMAP."PLANET_FEATURES"  pf ,
           LATERAL FLATTEN (INPUT => pf."all_tags")               tag
    WHERE  pf."feature_type"              = 'multipolygons'
      AND  tag.value:"key"::STRING        = 'wikidata'
      AND  tag.value:"value"::STRING      = 'Q191'
),

candidates AS (                                           -- 2.  candidate multipolygons (no wikidata)
    SELECT
        mp."osm_way_id",
        TO_GEOGRAPHY(mp."geometry")                                   AS geom,
        MAX( CASE WHEN t.value:"key"::STRING = 'name'
                  THEN t.value:"value"::STRING END )                  AS poly_name
    FROM   GEO_OPENSTREETMAP.GEO_OPENSTREETMAP."PLANET_FEATURES"  mp ,
           LATERAL FLATTEN (INPUT => mp."all_tags")               t ,
           q191_env
    WHERE  mp."feature_type" = 'multipolygons'
      AND  ST_INTERSECTS( q191_env.env , TO_GEOGRAPHY(mp."geometry") )
    GROUP BY mp."osm_way_id", mp."geometry"
    HAVING MAX( CASE WHEN t.value:"key"::STRING = 'wikidata' THEN 1 ELSE 0 END ) = 0
),

ranked AS (                                               -- 3.  count enclosed point features
    SELECT
        cand."osm_way_id",
        cand.poly_name,
        COUNT(pt."osm_id")                           AS point_cnt
    FROM   candidates                                            cand
           JOIN GEO_OPENSTREETMAP.GEO_OPENSTREETMAP."PLANET_FEATURES_POINTS"  pt
                 ON ST_CONTAINS( cand.geom , TO_GEOGRAPHY(pt."geometry") )
    GROUP BY cand."osm_way_id", cand.poly_name
)

SELECT
    "osm_way_id",
    poly_name,
    point_cnt
FROM   ranked
ORDER  BY point_cnt DESC NULLS LAST
LIMIT  2;