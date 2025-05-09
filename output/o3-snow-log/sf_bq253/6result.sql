WITH q1095_poly AS (               -- ❶ multipolygon carrying wikidata = Q1095
    SELECT TO_GEOGRAPHY("geometry") AS geom
    FROM   GEO_OPENSTREETMAP.GEO_OPENSTREETMAP."PLANET_FEATURES"
    WHERE  "feature_type" = 'multipolygons'
      AND  "all_tags"     ILIKE '%"wikidata"%Q1095%'
    ORDER BY "osm_timestamp" DESC NULLS LAST
    LIMIT 1
),
candidate_relations AS (           -- ❷ relations that intersect that polygon,
    SELECT
        r."id"                                            AS relation_id,
        TO_GEOGRAPHY(r."geometry")                        AS rel_geom,
        name_tag.value:"value"::STRING                    AS relation_name
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP."PLANET_RELATIONS" r,
         q1095_poly,
         LATERAL FLATTEN( INPUT => r."all_tags" ) name_tag
    WHERE r."geometry" IS NOT NULL
      AND ST_INTERSECTS( TO_GEOGRAPHY(r."geometry"), q1095_poly.geom )
      AND name_tag.value:"key"::STRING = 'name'           -- has a name
      AND r."all_tags" NOT ILIKE '%"wikidata"%'           -- but no wikidata tag
),
features_inside_poly AS (          -- ❸ all features inside the Q1095 polygon
    SELECT
        TO_GEOGRAPHY(f."geometry")                AS feat_geom,
        CASE WHEN f."all_tags" ILIKE '%"wikidata"%' THEN 1 ELSE 0 END AS has_wikidata
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP."PLANET_FEATURES" f,
         q1095_poly
    WHERE f."geometry" IS NOT NULL
      AND ST_INTERSECTS( TO_GEOGRAPHY(f."geometry"), q1095_poly.geom )
),
relation_statistics AS (           -- ❹ count how many of those features each
                                   --    candidate relation encompasses
    SELECT
        cr.relation_id,
        cr.relation_name,
        COUNT(*)                       AS feature_cnt,
        MAX(fi.has_wikidata)           AS has_wikidata_feature   -- at least one
    FROM   candidate_relations cr
    JOIN   features_inside_poly fi
           ON ST_INTERSECTS( fi.feat_geom , cr.rel_geom )
    GROUP  BY cr.relation_id, cr.relation_name
),
winner AS (                         -- ❺ pick the relation with most features
    SELECT relation_name
    FROM   relation_statistics
    WHERE  has_wikidata_feature = 1          -- at least one feature has wikidata
    ORDER  BY feature_cnt DESC NULLS LAST
    LIMIT 1
)
SELECT relation_name
FROM   winner;