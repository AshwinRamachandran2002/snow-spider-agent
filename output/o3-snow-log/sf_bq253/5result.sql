/* --------------------------------------------------------------
   Find the relation (without a wikidata tag, but having a name)
   that overlaps the area of the multipolygon whose wikidata is
   Q1095 and that contains the greatest number of OSM features.
   At least one of those contained features must itself carry a
   wikidata tag.  Return that relation’s name.
----------------------------------------------------------------*/
WITH q1095_area AS (        -- geometry of the Q1095 multipolygon
    SELECT TO_GEOGRAPHY(pf."geometry") AS geom
    FROM   GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES pf,
           LATERAL FLATTEN (INPUT => pf."all_tags") tag
    WHERE  pf."feature_type" = 'multipolygons'
      AND  tag.value:"key"::STRING   = 'wikidata'
      AND  tag.value:"value"::STRING = 'Q1095'
    LIMIT 1
),
candidate_relations AS (    -- relations with name, no wikidata, overlapping Q1095
    SELECT  pr."id",
            TO_GEOGRAPHY(pr."geometry")                       AS geom,
            MAX( CASE WHEN tg.value:"key"::STRING = 'name'
                       THEN tg.value:"value"::STRING END )    AS rel_name
    FROM    GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_RELATIONS pr,
            LATERAL FLATTEN (INPUT => pr."all_tags") tg,
            q1095_area q
    WHERE   pr."geometry" IS NOT NULL
      AND   ST_INTERSECTS( TO_GEOGRAPHY(pr."geometry"), q.geom )
    GROUP BY pr."id", pr."geometry"
    HAVING  SUM(CASE WHEN tg.value:"key"::STRING = 'name'     THEN 1 ELSE 0 END) > 0
       AND  SUM(CASE WHEN tg.value:"key"::STRING = 'wikidata' THEN 1 ELSE 0 END) = 0
),
features_inside AS (        -- features inside each candidate relation
    SELECT  cr."id"                                          AS relation_id,
            /* build a surrogate feature id to avoid double-counting                */
            COALESCE( CAST(pf."osm_way_id" AS STRING),
                      CAST(pf."osm_id"     AS STRING),
                      CONCAT('F_', HASH(pf."geometry")) )    AS feature_uid,
            MAX( CASE WHEN ft.value:"key"::STRING = 'wikidata'
                       THEN 1 ELSE 0 END )                   AS feature_has_wd
    FROM    candidate_relations             cr
    JOIN    GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES pf
               ON pf."geometry" IS NOT NULL
              AND ST_INTERSECTS( TO_GEOGRAPHY(pf."geometry"), cr.geom )
    LEFT JOIN LATERAL FLATTEN (INPUT => pf."all_tags") ft
    GROUP BY relation_id, feature_uid
),
relation_stats AS (         -- count features & those with wikidata
    SELECT  relation_id,
            COUNT(*)                             AS feature_cnt,
            SUM(feature_has_wd)                 AS wd_feature_cnt
    FROM    features_inside
    GROUP BY relation_id
)
SELECT  cr.rel_name AS relation_name
FROM    candidate_relations cr
JOIN    relation_stats     rs  ON rs.relation_id = cr."id"
WHERE   rs.wd_feature_cnt > 0              -- at least one feature with wikidata
ORDER BY rs.feature_cnt DESC NULLS LAST    -- most features first
LIMIT 1;