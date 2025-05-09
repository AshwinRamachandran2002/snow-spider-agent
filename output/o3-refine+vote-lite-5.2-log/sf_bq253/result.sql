WITH target AS (   -- multipolygon that carries wikidata = Q1095
    SELECT
        TO_GEOGRAPHY("geometry") AS geom
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES
    WHERE "feature_type" = 'multipolygons'
      AND "all_tags"::string ILIKE '%"wikidata"%Q1095%'
    ORDER BY "osm_timestamp" DESC          -- take the newest version, if several exist
    LIMIT 1
),
candidate_relations AS (     -- relations that overlap the target area, have a name, but NO wikidata tag
    SELECT
        r."id",
        TO_GEOGRAPHY(r."geometry")                     AS geom,
        REGEXP_SUBSTR( r."all_tags"::string ,
                       '"key":"name","value":"([^"]+)"' , 1 , 1 , 'e' , 1) AS rel_name
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_RELATIONS r,
         target t
    WHERE ST_INTERSECTS( TO_GEOGRAPHY(r."geometry") , t.geom )
      AND rel_name IS NOT NULL
      AND r."all_tags"::string NOT ILIKE '%"wikidata"%'
),
feature_coverage AS (       -- how many planet_features each relation encloses and how many of them have wikidata
    SELECT
        cr."id",
        cr.rel_name,
        COUNT(*)                                                          AS total_features,
        SUM( CASE WHEN pf."all_tags"::string ILIKE '%"wikidata"%' THEN 1 ELSE 0 END ) AS wikidata_features
    FROM candidate_relations cr
    JOIN GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES pf
         ON ST_INTERSECTS( TO_GEOGRAPHY(pf."geometry") , cr.geom )
    GROUP BY cr."id", cr.rel_name
    HAVING wikidata_features > 0               -- at least one enclosed feature owns a wikidata tag
)
SELECT rel_name               -- name of the relation that encloses the most features
FROM feature_coverage
ORDER BY total_features DESC NULLS LAST, rel_name
LIMIT 1;