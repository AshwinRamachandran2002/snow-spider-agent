WITH q_area AS (   -- area of the multipolygon tagged wikidata = Q1095
    SELECT ST_GEOGFROMWKB(pf."geometry") AS geog
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES pf,
         LATERAL FLATTEN(INPUT => pf."all_tags") tag
    WHERE pf."feature_type" = 'multipolygons'
          AND tag.value:"key"::string  = 'wikidata'
          AND tag.value:"value"::string = 'Q1095'
    LIMIT 1
),

candidate_relations AS (            -- named relations without their own wikidata tag
    SELECT
        r."id",
        MAX(CASE WHEN tag.value:"key"::string = 'name'
                 THEN tag.value:"value"::string END)              AS name,
        MAX(CASE WHEN tag.value:"key"::string = 'wikidata' THEN 1 ELSE 0 END)
                                                                   AS has_wikidata,
        ST_GEOGFROMWKB(r."geometry")                              AS geog
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_RELATIONS r,
         LATERAL FLATTEN(INPUT => r."all_tags") tag
    GROUP BY r."id", r."geometry"
    HAVING name IS NOT NULL
       AND has_wikidata = 0
),

relation_feature_counts AS (        -- count wikidata‑tagged features inside each relation
    SELECT
        rel.name,
        COUNT(*) AS wikidata_feature_cnt
    FROM candidate_relations rel
    JOIN q_area q
          ON ST_INTERSECTS(rel.geog, q.geog)            -- relation overlaps Q1095 area
    JOIN GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES pf
          ON ST_INTERSECTS(ST_GEOGFROMWKB(pf."geometry"), rel.geog)
    CROSS JOIN LATERAL FLATTEN(INPUT => pf."all_tags") ptag
    WHERE ptag.value:"key"::string = 'wikidata'          -- feature has wikidata tag
    GROUP BY rel.name
)

SELECT name
FROM relation_feature_counts
ORDER BY wikidata_feature_cnt DESC NULLS LAST, name
LIMIT 1;