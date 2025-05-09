WITH qpoly AS (   -- the reference multipolygon having wikidata = 'Q191'
    SELECT ST_UNION_AGG( TO_GEOGRAPHY(pf."geometry") ) AS "geom"
    FROM   GEO_OPENSTREETMAP.GEO_OPENSTREETMAP."PLANET_FEATURES" pf,
           LATERAL FLATTEN( input => pf."all_tags") tag
    WHERE  pf."feature_type" = 'multipolygons'
      AND  tag.value:"key"::STRING   = 'wikidata'
      AND  tag.value:"value"::STRING = 'Q191'
),

candidates AS (   -- multipolygons inside Q191 but WITHOUT their own wikidata tag
    SELECT  pf2."osm_way_id",
            TO_GEOGRAPHY(pf2."geometry")                                         AS "geom",
            MAX( CASE WHEN tag2.value:"key"::STRING = 'name'
                      THEN tag2.value:"value"::STRING END )                      AS "name"
    FROM    GEO_OPENSTREETMAP.GEO_OPENSTREETMAP."PLANET_FEATURES"  pf2,
            LATERAL FLATTEN( input => pf2."all_tags") tag2,
            qpoly
    WHERE   pf2."feature_type" = 'multipolygons'
      AND   ST_CONTAINS( qpoly."geom" , TO_GEOGRAPHY(pf2."geometry") )
    GROUP BY pf2."osm_way_id", pf2."geometry"
    HAVING  MAX( CASE WHEN tag2.value:"key"::STRING = 'wikidata' THEN 1 ELSE 0 END ) = 0
)

SELECT  c."osm_way_id",
        COALESCE(c."name", '')                         AS "name",
        COUNT(*)                                       AS "points_inside"
FROM    candidates                 c
JOIN    GEO_OPENSTREETMAP.GEO_OPENSTREETMAP."PLANET_FEATURES_POINTS" pts
       ON ST_CONTAINS( c."geom", TO_GEOGRAPHY( pts."geometry") )
GROUP BY c."osm_way_id", c."name"
ORDER BY "points_inside" DESC NULLS LAST
LIMIT 2;