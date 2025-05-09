WITH q1095 AS (                                                            -- multipolygon tagged with Wikidata = Q1095
    SELECT TO_GEOGRAPHY(pf."geometry") AS geom
    FROM   "GEO_OPENSTREETMAP"."GEO_OPENSTREETMAP"."PLANET_FEATURES" pf,
           LATERAL FLATTEN(input => pf."all_tags") tag
    WHERE  tag.value:"key"::STRING  = 'wikidata'
      AND  tag.value:"value"::STRING = 'Q1095'
      AND  pf."feature_type" = 'multipolygons'
    LIMIT 1
),
candidate_relations AS (                                                   -- relations intersecting the Q1095 area
    SELECT
           r."id"                                                     AS relation_id,
           TO_GEOGRAPHY(r."geometry")                                 AS relation_geom,
           MAX(CASE WHEN at.value:"key"::STRING = 'name'
                     THEN at.value:"value"::STRING END)               AS relation_name
    FROM   "GEO_OPENSTREETMAP"."GEO_OPENSTREETMAP"."PLANET_RELATIONS" r,
           LATERAL FLATTEN(input => r."all_tags") at,
           q1095
    WHERE  ST_INTERSECTS(q1095.geom , TO_GEOGRAPHY(r."geometry"))
    GROUP  BY r."id", r."geometry"
    HAVING MAX(CASE WHEN at.value:"key"::STRING = 'wikidata' THEN 1 ELSE 0 END) = 0   -- no wikidata on relation
       AND MAX(CASE WHEN at.value:"key"::STRING = 'name'     THEN 1 ELSE 0 END) = 1   -- has a name
),
relation_feature_stats AS (                                                -- count features each relation encloses
    SELECT
           cr.relation_id,
           cr.relation_name,
           COUNT(DISTINCT COALESCE(pf."osm_way_id"::STRING,
                                   pf."osm_id"::STRING))              AS feature_cnt,
           MAX(CASE WHEN tf.value:"key"::STRING = 'wikidata'
                    THEN 1 ELSE 0 END)                                AS has_feature_wikidata
    FROM   candidate_relations cr
    JOIN   "GEO_OPENSTREETMAP"."GEO_OPENSTREETMAP"."PLANET_FEATURES"   pf
           ON  ST_INTERSECTS(TO_GEOGRAPHY(pf."geometry"), cr.relation_geom)
           AND ST_INTERSECTS(TO_GEOGRAPHY(pf."geometry"), (SELECT geom FROM q1095))
    ,     LATERAL FLATTEN(input => pf."all_tags") tf
    GROUP  BY cr.relation_id, cr.relation_name
)
SELECT relation_name
FROM   relation_feature_stats
WHERE  has_feature_wikidata = 1                                            -- at least one enclosed feature has wikidata
ORDER BY feature_cnt DESC NULLS LAST                                       -- most features first
LIMIT 1;