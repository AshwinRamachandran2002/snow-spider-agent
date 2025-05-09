WITH estonia AS (  -- geometry of the Wikidata=Q191 multipolygon
    SELECT TO_GEOGRAPHY(p."geometry") AS geom
    FROM   GEO_OPENSTREETMAP.GEO_OPENSTREETMAP."PLANET_FEATURES"      p,
           LATERAL FLATTEN(input => p."all_tags")                     t
    WHERE  p."feature_type" = 'multipolygons'
      AND  t.value:"key"::STRING   = 'wikidata'
      AND  t.value:"value"::STRING = 'Q191'
    LIMIT 1
),
estonia_bbox AS (                 -- simple envelope for coarse filtering
    SELECT ST_ENVELOPE(geom) AS bbox
    FROM   estonia
),
candidate_polys AS (              -- multipolygons inside Estonia without a wikidata tag
    SELECT  pf."osm_way_id",
            TO_GEOGRAPHY(MIN(pf."geometry"))                                AS geom,
            MAX(CASE WHEN tag.value:"key"::STRING = 'name'
                     THEN tag.value:"value"::STRING END)                    AS name
    FROM    GEO_OPENSTREETMAP.GEO_OPENSTREETMAP."PLANET_FEATURES"  pf
    JOIN    estonia_bbox eb
          ON ST_COVERS(eb.bbox , TO_GEOGRAPHY(pf."geometry"))
    ,       LATERAL FLATTEN(input => pf."all_tags", outer => TRUE) tag
    WHERE   pf."feature_type" = 'multipolygons'
    GROUP BY pf."osm_way_id"
    HAVING  SUM(IFF(tag.value:"key"::STRING = 'wikidata',1,0)) = 0
),
scored AS (                       -- count point-features contained in each candidate
    SELECT  c."osm_way_id",
            c.name,
            COUNT(*) AS point_cnt
    FROM    candidate_polys                                     c
    JOIN    GEO_OPENSTREETMAP.GEO_OPENSTREETMAP."PLANET_FEATURES_POINTS" pt
          ON ST_CONTAINS(c.geom , TO_GEOGRAPHY(pt."geometry"))
    GROUP BY c."osm_way_id", c.name
)
SELECT  "osm_way_id",
        COALESCE(name,'<< no name tag >>') AS "name",
        point_cnt
FROM    scored
ORDER BY point_cnt DESC NULLS LAST
LIMIT 2;