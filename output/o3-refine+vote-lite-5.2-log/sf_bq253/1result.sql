/* -----------------------------------------------------------------
   Return the name of the OSM relation (without its own wikidata tag)
   that overlaps the multipolygon tagged wikidata = 'Q1095' and
   contains the most PLANET_FEATURES, while at least one such feature
   carries a wikidata tag.
------------------------------------------------------------------*/
WITH
/* 1.  Geometry of the multipolygon that has wikidata = Q1095 ------*/
base_poly AS (
    SELECT
        ST_UNION_AGG(TO_GEOGRAPHY("geometry")) AS geom
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP."PLANET_FEATURES" f
         , LATERAL FLATTEN(INPUT => f."all_tags") t
    WHERE t.value:"key"::string   = 'wikidata'
      AND t.value:"value"::string = 'Q1095'
),

/* 2.  Extract name / wikidata flags for every relation ------------*/
relation_tag_summary AS (
    SELECT
        r."id"                                     AS relation_id,
        ANY_VALUE(r."geometry")                    AS relation_geom,
        MAX(IFF(t.value:"key"::string = 'name',
                t.value:"value"::string , NULL))   AS relation_name,
        MAX(IFF(t.value:"key"::string = 'wikidata',1,0))  AS has_wikidata
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP."PLANET_RELATIONS" r
         , LATERAL FLATTEN(INPUT => r."all_tags") t
    GROUP BY r."id"
),

/* 3.  Keep only named relations w/o wikidata that touch Q1095 ------*/
candidate_relations AS (
    SELECT
        s.relation_id,
        s.relation_geom,
        s.relation_name
    FROM relation_tag_summary s
         , base_poly bp
    WHERE s.relation_name IS NOT NULL
      AND s.has_wikidata = 0
      AND s.relation_geom IS NOT NULL
      AND ST_INTERSECTS(TO_GEOGRAPHY(s.relation_geom), bp.geom)
),

/* 4.  Features inside each candidate relation (and inside Q1095) --*/
feature_flags AS (
    SELECT
        cr.relation_id,
        cr.relation_name,
        /* unique key for the feature (way‑id preferred) */
        COALESCE(pf."osm_way_id", pf."osm_id")                 AS feat_key,
        /* 1 if this feature holds a wikidata tag */
        MAX(IFF(pt.value:"key"::string = 'wikidata',1,0))      AS has_wd
    FROM candidate_relations cr
         JOIN GEO_OPENSTREETMAP.GEO_OPENSTREETMAP."PLANET_FEATURES" pf
           ON pf."geometry" IS NOT NULL
          AND ST_INTERSECTS(
                 TO_GEOGRAPHY(pf."geometry"),
                 TO_GEOGRAPHY(cr.relation_geom)
              )
         CROSS JOIN base_poly bp
         LEFT JOIN LATERAL FLATTEN(INPUT => pf."all_tags") pt
    WHERE ST_INTERSECTS(TO_GEOGRAPHY(pf."geometry"), bp.geom)
    GROUP BY cr.relation_id, cr.relation_name, COALESCE(pf."osm_way_id", pf."osm_id")
),

/* 5.  Aggregate counts per relation -------------------------------*/
relation_stats AS (
    SELECT
        relation_id,
        relation_name,
        COUNT(*)           AS feature_cnt,
        SUM(has_wd)        AS wd_feature_cnt
    FROM feature_flags
    GROUP BY relation_id, relation_name
    HAVING wd_feature_cnt >= 1          -- needs at least one wikidata feature
)

/* 6.  Final answer ------------------------------------------------*/
SELECT relation_name
FROM relation_stats
ORDER BY feature_cnt DESC NULLS LAST, relation_id
LIMIT 1;