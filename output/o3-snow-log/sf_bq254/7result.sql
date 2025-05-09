WITH estonia_env AS (   -- envelope of the multipolygon that has wikidata = Q191
    SELECT ST_ENVELOPE( TO_GEOGRAPHY(pf."geometry") ) AS env_geom
    FROM   GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES pf
           ,LATERAL FLATTEN( INPUT => pf."all_tags") t
    WHERE  pf."feature_type" = 'multipolygons'
      AND  t.value:"key"::STRING   = 'wikidata'
      AND  t.value:"value"::STRING = 'Q191'
    LIMIT 1
),
candidates AS (         -- multipolygons inside the envelope and WITHOUT a wikidata tag
    SELECT pf."osm_way_id",
           pf."geometry",
           MAX( CASE WHEN tag.value:"key"::STRING = 'name'
                     THEN tag.value:"value"::STRING END ) AS "name"
    FROM   GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES pf
           ,estonia_env
           ,LATERAL FLATTEN( INPUT => pf."all_tags") tag
    WHERE  pf."feature_type" = 'multipolygons'
      AND  ST_WITHIN( TO_GEOGRAPHY(pf."geometry"), estonia_env.env_geom )
    GROUP BY pf."osm_way_id", pf."geometry"
    HAVING MAX( CASE WHEN tag.value:"key"::STRING = 'wikidata' THEN 1 ELSE 0 END ) = 0
),
point_counts AS (       -- count points that fall inside each candidate polygon
    SELECT  cand."osm_way_id",
            cand."name",
            COUNT(*) AS pts_inside
    FROM    candidates              cand
    JOIN    GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES_POINTS p
      ON    ST_WITHIN( TO_GEOGRAPHY(p."geometry"), TO_GEOGRAPHY(cand."geometry") )
    GROUP BY cand."osm_way_id", cand."name"
)
SELECT  "osm_way_id",
        COALESCE("name",'')      AS "name",
        pts_inside
FROM    point_counts
ORDER BY pts_inside DESC NULLS LAST
LIMIT 2;