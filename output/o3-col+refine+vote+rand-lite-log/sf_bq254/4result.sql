WITH q191 AS (   -- geometry of the multipolygon that carries wikidata = 'Q191'
    SELECT TO_GEOGRAPHY(pf."geometry") AS geo
    FROM   GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES pf
           , LATERAL FLATTEN (input => pf."all_tags") tag
    WHERE  pf."feature_type" = 'multipolygons'
      AND  tag.value:"key"   = 'wikidata'
      AND  tag.value:"value" = 'Q191'
    LIMIT 1
),
candidates AS (  -- multipolygons inside Q191 and **without** a wikidata tag
    SELECT  pf."osm_way_id",
            pf."geometry" AS wkb_geom,
            MAX(IFF(tag.value:"key" = 'name',
                    tag.value:"value"::STRING , NULL)) AS name
    FROM    GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES pf
            , q191
            , LATERAL FLATTEN (input => pf."all_tags") tag
    WHERE   pf."feature_type" = 'multipolygons'
      AND   ST_CONTAINS(q191.geo , TO_GEOGRAPHY(pf."geometry"))
    GROUP BY pf."osm_way_id", pf."geometry"
    HAVING  SUM(CASE WHEN tag.value:"key" = 'wikidata' THEN 1 ELSE 0 END) = 0
),
point_counts AS (  -- number of points that fall inside each candidate multipolygon
    SELECT  c."osm_way_id",
            c.name,
            COUNT(*) AS num_points
    FROM    candidates                c
    JOIN    GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES_POINTS pt
              ON ST_CONTAINS(TO_GEOGRAPHY(c.wkb_geom),
                              TO_GEOGRAPHY(pt."geometry"))
    GROUP   BY c."osm_way_id", c.name
)
SELECT  "osm_way_id",
        name,
        num_points
FROM    point_counts
ORDER BY num_points DESC NULLS LAST
LIMIT   2;