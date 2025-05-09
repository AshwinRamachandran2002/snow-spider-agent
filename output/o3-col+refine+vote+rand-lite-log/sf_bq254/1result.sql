WITH estonia AS (   -- multipolygon of Estonia (wikidata = Q191)
    SELECT TO_GEOGRAPHY(pf."geometry") AS est_geo
    FROM   "GEO_OPENSTREETMAP"."GEO_OPENSTREETMAP"."PLANET_FEATURES" pf,
           LATERAL FLATTEN(input => pf."all_tags") t
    WHERE  t.value:"key"::STRING  = 'wikidata'
      AND  t.value:"value"::STRING = 'Q191'
      AND  pf."feature_type"       = 'multipolygons'
    LIMIT 1
),
candidates AS (      -- multipolygons inside Estonia, without a wikidata tag, with a name
    SELECT
        pf."osm_way_id",
        pf."geometry",
        name_tag.value:"value"::STRING AS "name"
    FROM   "GEO_OPENSTREETMAP"."GEO_OPENSTREETMAP"."PLANET_FEATURES" pf
    JOIN   estonia e
          ON ST_INTERSECTS(e.est_geo , TO_GEOGRAPHY(pf."geometry"))
    ,      LATERAL FLATTEN(input => pf."all_tags") name_tag
    WHERE  pf."feature_type" = 'multipolygons'
      AND  name_tag.value:"key"::STRING = 'name'
      AND  TO_VARCHAR(pf."all_tags") NOT ILIKE '%"key":"wikidata"%'   -- exclude those with a wikidata tag
)
SELECT
    c."osm_way_id",
    c."name",
    COUNT(*) AS points_inside
FROM   candidates c
JOIN   "GEO_OPENSTREETMAP"."GEO_OPENSTREETMAP"."PLANET_FEATURES_POINTS" pt
       ON ST_CONTAINS(
              TO_GEOGRAPHY(c."geometry"),
              TO_GEOGRAPHY(pt."geometry")
          )
GROUP  BY c."osm_way_id", c."name"
ORDER  BY points_inside DESC NULLS LAST
LIMIT 2;