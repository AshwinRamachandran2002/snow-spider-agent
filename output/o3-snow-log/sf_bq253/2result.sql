WITH  /* 1) geometry of the multipolygon tagged wikidata = Q1095 */
q1095 AS (   
    SELECT TO_GEOGRAPHY(f."geometry") AS geom_q1095
    FROM   "GEO_OPENSTREETMAP"."GEO_OPENSTREETMAP"."PLANET_FEATURES"  f,
           LATERAL FLATTEN(INPUT => f."all_tags") tag
    WHERE  tag.value:"key"::STRING  = 'wikidata'
      AND  tag.value:"value"::STRING = 'Q1095'
    LIMIT 1
),
/* 2) relation-level tag summary (name / has_wikidata) */
rel_tag_summary AS (
    SELECT r."id"                                                   AS relation_id,
           MAX(CASE WHEN t.value:"key"::STRING = 'name'
                    THEN t.value:"value"::STRING END)               AS relation_name,
           MAX(CASE WHEN t.value:"key"::STRING = 'wikidata'
                    THEN 1 ELSE 0 END)                             AS rel_has_wikidata
    FROM   "GEO_OPENSTREETMAP"."GEO_OPENSTREETMAP"."PLANET_RELATIONS" r,
           LATERAL FLATTEN(INPUT => r."all_tags") t
    GROUP  BY r."id"
),
/* 3) candidate relations: named, no wikidata, intersect Q1095 */
rel_candidates AS (
    SELECT  r."id"                                            AS relation_id,
            TO_GEOGRAPHY(r."geometry")                        AS geom_rel,
            s.relation_name
    FROM    "GEO_OPENSTREETMAP"."GEO_OPENSTREETMAP"."PLANET_RELATIONS"  r
    JOIN    rel_tag_summary  s   ON s.relation_id = r."id",
            q1095
    WHERE   r."geometry" IS NOT NULL
      AND   s.relation_name IS NOT NULL
      AND   s.rel_has_wikidata = 0
      AND   ST_INTERSECTS( TO_GEOGRAPHY(r."geometry"), q1095.geom_q1095 )
),
/* 4a) flag features that possess a wikidata tag */
feature_wikidata AS (
    SELECT  f."osm_way_id",
            MAX( IFF(tag.value:"key"::STRING = 'wikidata', 1, 0) ) AS has_wikidata
    FROM    "GEO_OPENSTREETMAP"."GEO_OPENSTREETMAP"."PLANET_FEATURES" f
    CROSS   JOIN LATERAL FLATTEN(INPUT => f."all_tags") tag
    GROUP   BY f."osm_way_id"
),
/* 4b) geometry of every feature + its wikidata-flag */
features_flag AS (
    SELECT  TO_GEOGRAPHY(f."geometry")        AS geom_feat,
            COALESCE(w.has_wikidata, 0)       AS feature_has_wikidata
    FROM    "GEO_OPENSTREETMAP"."GEO_OPENSTREETMAP"."PLANET_FEATURES"  f
    LEFT    JOIN feature_wikidata  w ON w."osm_way_id" = f."osm_way_id"
    WHERE   f."geometry" IS NOT NULL
),
/* 5) count features inside each candidate relation */
rel_feature_stats AS (
    SELECT  rc.relation_id,
            rc.relation_name,
            COUNT(*)                              AS feature_cnt,
            MAX(feature_has_wikidata)             AS any_feature_with_wikidata
    FROM    rel_candidates   rc
    JOIN    features_flag    ff
           ON ST_INTERSECTS( ff.geom_feat, rc.geom_rel )
    GROUP   BY rc.relation_id, rc.relation_name
    HAVING  any_feature_with_wikidata = 1         -- at least one enclosed feature has wikidata
)
/* 6) return the relation possessing the most enclosed features */
SELECT  relation_name
FROM    rel_feature_stats
ORDER BY feature_cnt DESC NULLS LAST
LIMIT 1;