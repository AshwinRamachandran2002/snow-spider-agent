/*  Return the name of the relation (with a name but without a wikidata tag) that
    intersects the area of the multipolygon wikidata=Q1095 and encloses the
    largest number of planet_features, provided at least one of those features
    has its own wikidata tag.                                            */

WITH q1095 AS (     -- geometry of the Q1095 multipolygon
    SELECT ST_GEOGFROMWKB(pf."geometry") AS geog
    FROM   GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES pf,
           LATERAL FLATTEN(input => pf."all_tags") tag
    WHERE  tag.value:"key"::STRING  = 'wikidata'
      AND  tag.value:"value"::STRING = 'Q1095'
    LIMIT 1
),

/* restrict planet_features to the same geographic neighborhood as Q1095   */
pf_q AS (
    SELECT  pf."geometry"                                          AS geom ,
            MAX(CASE WHEN tag.value:"key"::STRING = 'wikidata'
                     THEN 1 ELSE 0 END)                           AS has_wikidata
    FROM    GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES pf,
            LATERAL FLATTEN(input => pf."all_tags") tag ,
            q1095
    WHERE   ST_INTERSECTS(ST_GEOGFROMWKB(pf."geometry"), q1095.geog)
    GROUP  BY pf."geometry"
),

/* relations intersecting Q1095 that have a name but no wikidata tag       */
candidate_rel AS (
    SELECT  pr."id",
            pr."geometry",
            MAX(CASE WHEN tg.value:"key"::STRING = 'name'
                     THEN tg.value:"value"::STRING END) AS rel_name
    FROM    GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_RELATIONS pr,
            LATERAL FLATTEN(input => pr."all_tags") tg,
            q1095
    WHERE   ST_INTERSECTS(ST_GEOGFROMWKB(pr."geometry"), q1095.geog)
    GROUP  BY pr."id", pr."geometry"
    HAVING  COUNT_IF(tg.value:"key"::STRING = 'name')     > 0
       AND  COUNT_IF(tg.value:"key"::STRING = 'wikidata') = 0
),

/* count how many of the filtered planet_features each candidate covers    */
rel_feature_stats AS (
    SELECT  cr."id",
            cr.rel_name,
            COUNT(*)                         AS feature_cnt,
            MAX(pf_q.has_wikidata)           AS has_wd_feat
    FROM    candidate_rel cr ,
            pf_q
    WHERE   ST_INTERSECTS( ST_GEOGFROMWKB(cr."geometry"),
                           ST_GEOGFROMWKB(pf_q.geom) )
    GROUP  BY cr."id", cr.rel_name
)

SELECT rel_name AS "relation_name"
FROM   rel_feature_stats
WHERE  has_wd_feat = 1
ORDER  BY feature_cnt DESC NULLS LAST
LIMIT 1;