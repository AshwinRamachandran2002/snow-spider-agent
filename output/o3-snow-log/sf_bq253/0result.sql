WITH qpoly AS (         /* geometry of the multipolygon that carries wikidata = Q1095 */
    SELECT TO_GEOGRAPHY("geometry") AS geom
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP."PLANET_FEATURES"
    WHERE "feature_type" = 'multipolygons'
      AND "all_tags" ILIKE '%"wikidata"%Q1095%'
      AND "geometry" IS NOT NULL
    ORDER BY "osm_timestamp" DESC
    LIMIT 1
),
/* extract name and wikidata flag for every relation once */
relations_tagged AS (
    SELECT
        r."id",
        TO_GEOGRAPHY(r."geometry")                               AS geom,
        MAX(CASE WHEN t.value:"key"::string = 'name'
                 THEN t.value:"value"::string END)               AS name,
        MAX(CASE WHEN t.value:"key"::string = 'wikidata'
                 THEN 1 END)                                     AS has_wikidata
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP."PLANET_RELATIONS" r,
         LATERAL FLATTEN (INPUT => r."all_tags") t
    WHERE r."geometry" IS NOT NULL
    GROUP BY r."id", r."geometry"
),
/* relations intersecting the Q1095 area, with a name, and without a wikidata tag */
candidate_relations AS (
    SELECT rt."id", rt.name, rt.geom
    FROM relations_tagged rt
    JOIN qpoly q
      ON ST_INTERSECTS(rt.geom, q.geom)
    WHERE rt.name IS NOT NULL
      AND rt.has_wikidata IS NULL
),
/* planet features, flagged whether they themselves carry a wikidata tag */
features_with_flag AS (
    SELECT
        TO_GEOGRAPHY(pf."geometry")                               AS geom,
        CASE WHEN pf."all_tags" ILIKE '%"wikidata"%' THEN 1 ELSE 0 END AS has_wikidata
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP."PLANET_FEATURES" pf
    WHERE pf."geometry" IS NOT NULL
),
/* count features (and those with wikidata) inside each candidate relation & Q1095 area */
rel_feature_counts AS (
    SELECT
        cr.name,
        COUNT(*)                     AS feature_cnt,
        SUM(f.has_wikidata)          AS wikidata_feat_cnt
    FROM candidate_relations cr
    JOIN features_with_flag f
      ON ST_INTERSECTS(f.geom, cr.geom)
    JOIN qpoly q
      ON ST_INTERSECTS(f.geom, q.geom)
    GROUP BY cr.name
)
SELECT name
FROM rel_feature_counts
WHERE wikidata_feat_cnt > 0
ORDER BY feature_cnt DESC NULLS LAST
LIMIT 1;