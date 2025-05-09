WITH q_poly AS (   -- geometry of the feature whose wikidata = 'Q1095'
    SELECT TO_GEOGRAPHY("geometry") AS geom_q
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES,
         LATERAL FLATTEN(input => "all_tags") tag
    WHERE tag.value:"key"  = 'wikidata'
      AND tag.value:"value" = 'Q1095'
    LIMIT 1
),

relations AS (     -- candidate relations (have name, lack wikidata)
    SELECT pr."id",
           TO_GEOGRAPHY(pr."geometry")               AS geom_r,
           MAX(CASE WHEN tag.value:"key" = 'name'
                    THEN tag.value:"value"::string END)     AS relation_name,
           MAX(CASE WHEN tag.value:"key" = 'wikidata'
                    THEN tag.value:"value"::string END)     AS relation_wikidata
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_RELATIONS pr,
         LATERAL FLATTEN(input => pr."all_tags") tag
    WHERE pr."geometry" IS NOT NULL
      AND pr."visible"  = TRUE
    GROUP BY pr."id", pr."geometry"
    HAVING relation_name IS NOT NULL          -- has a name
       AND relation_wikidata IS NULL          -- but no wikidata tag
),

features AS (      -- planet features, mark those carrying wikidata
    SELECT pf."osm_id",
           pf."osm_way_id",
           TO_GEOGRAPHY(pf."geometry")        AS geom_f,
           MAX(CASE WHEN tag.value:"key" = 'wikidata' THEN 1 ELSE 0 END) AS has_wikidata
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES pf,
         LATERAL FLATTEN(input => pf."all_tags") tag
    WHERE pf."geometry" IS NOT NULL
    GROUP BY pf."osm_id", pf."osm_way_id", pf."geometry"
),

rel_feat AS (      -- features that lie inside both the Q1095 area and each relation
    SELECT r."id"                AS relation_id,
           r.relation_name,
           COUNT(*)              AS feature_cnt,
           SUM(f.has_wikidata)   AS wd_cnt
    FROM relations r
    CROSS JOIN q_poly q
    JOIN features f
      ON ST_INTERSECTS(f.geom_f , q.geom_q)   -- inside Q1095 area
     AND ST_INTERSECTS(f.geom_f , r.geom_r)   -- inside the relation
    GROUP BY r."id", r.relation_name
)

SELECT relation_name
FROM   rel_feat
WHERE  wd_cnt > 0                       -- at least one contained feature has wikidata
ORDER  BY feature_cnt DESC NULLS LAST,  -- most encompassing relation first
          relation_id
LIMIT  1;