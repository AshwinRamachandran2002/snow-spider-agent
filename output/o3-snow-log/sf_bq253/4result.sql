WITH q1095 AS (   -- multipolygon that has wikidata = Q1095
    SELECT "osm_id"::STRING AS id_str
    FROM   GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES
    WHERE  "feature_type" = 'multipolygons'
      AND  "all_tags" ILIKE '%"wikidata"%Q1095%'
    LIMIT 1
),
candidate_relations AS (   -- relations that contain that multipolygon, have a name, but no wikidata tag
    SELECT  r."id",
            r."all_tags",
            r."members",
            ARRAY_SIZE(TRY_PARSE_JSON(r."members")) AS member_cnt
    FROM    GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_RELATIONS r
    JOIN    q1095
      ON    r."members" ILIKE '%' || q1095.id_str || '%'
    WHERE   r."all_tags" ILIKE '%"name"%'
      AND   r."all_tags" NOT ILIKE '%"wikidata"%'
),
relations_with_wikidata_member AS (   -- keep relations containing at least one member with a wikidata tag
    SELECT  DISTINCT cr."id",
            cr."all_tags",
            cr.member_cnt
    FROM    candidate_relations cr
    CROSS JOIN LATERAL FLATTEN( INPUT => TRY_PARSE_JSON(cr."members") ) f
    LEFT  JOIN GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES pf
           ON pf."osm_way_id" = GET(f.value,'id')::NUMBER
            OR pf."osm_id"    = GET(f.value,'id')::NUMBER
    WHERE   pf."all_tags" ILIKE '%"wikidata"%'
)
-- return the name of the relation that has the most members
SELECT  GET(t.value,'value')::STRING AS relation_name
FROM    relations_with_wikidata_member r
CROSS JOIN LATERAL FLATTEN( INPUT => TRY_PARSE_JSON(r."all_tags") ) t
WHERE   GET(t.value,'key')::STRING = 'name'
ORDER BY r.member_cnt DESC NULLS LAST
LIMIT 1;