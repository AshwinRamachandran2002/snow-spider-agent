WITH q1095 AS (                                   -- geometry of the multipolygon tagged Q1095
    SELECT TO_GEOGRAPHY("geometry") AS geom
    FROM   "GEO_OPENSTREETMAP"."GEO_OPENSTREETMAP"."PLANET_FEATURES",
           LATERAL FLATTEN(input => "all_tags") tag
    WHERE  tag.value:"key"::STRING = 'wikidata'
      AND  tag.value:"value"::STRING = 'Q1095'
    LIMIT 1
), rels AS (                                      -- relations having a name, but no wikidata tag
    SELECT  pr."id",
            TO_GEOGRAPHY(pr."geometry")                          AS rel_geom,
            MAX(CASE WHEN t.value:"key"::STRING = 'name'
                     THEN t.value:"value"::STRING END)           AS rel_name
    FROM    "GEO_OPENSTREETMAP"."GEO_OPENSTREETMAP"."PLANET_RELATIONS" pr,
            LATERAL FLATTEN(input => pr."all_tags") t
    GROUP BY pr."id", pr."geometry"
    HAVING  SUM(IFF(t.value:"key"::STRING = 'name'    ,1,0)) > 0   -- has a name
       AND  SUM(IFF(t.value:"key"::STRING = 'wikidata',1,0)) = 0   -- no wikidata tag
), counts AS (                                    -- count wikidata-tagged features inside both areas
    SELECT  rels.rel_name,
            COUNT(*) AS wikidata_feature_count
    FROM    rels
    JOIN    q1095                                     -- single row
    JOIN    "GEO_OPENSTREETMAP"."GEO_OPENSTREETMAP"."PLANET_FEATURES" pf
           ON pf."geometry" IS NOT NULL
          AND ST_ASWKT(TO_GEOGRAPHY(pf."geometry")) NOT ILIKE 'GEOMETRYCOLLECTION%'
          AND ST_ASWKT(TO_GEOGRAPHY(pf."geometry")) NOT ILIKE 'FEATURECOLLECTION%'
          AND ST_WITHIN(TO_GEOGRAPHY(pf."geometry"), rels.rel_geom)   -- inside relation
          AND ST_WITHIN(TO_GEOGRAPHY(pf."geometry"), q1095.geom)      -- inside Q1095
    ,      LATERAL FLATTEN(input => pf."all_tags") tagpf
    WHERE   tagpf.value:"key"::STRING = 'wikidata'                    -- feature has wikidata tag
    GROUP BY rels.rel_name
    HAVING  wikidata_feature_count > 0                                -- at least one such feature
)
SELECT rel_name
FROM   counts
ORDER BY wikidata_feature_count DESC NULLS LAST
LIMIT 1;