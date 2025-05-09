/*  ---------------------------------------------------------------
    Top-2 multipolygons located inside Estonia (wikidata = Q191)
    that themselves have NO 'wikidata' tag, ordered by the amount
    of point-features they contain.
------------------------------------------------------------------*/
WITH estonia AS (                              -- geometry of Estonia
    SELECT TO_GEOGRAPHY(pf."geometry") AS geo
    FROM   GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES  pf ,
           LATERAL FLATTEN(input => pf."all_tags")              t
    WHERE  pf."feature_type" = 'multipolygons'
      AND  t.value:"key"::STRING   = 'wikidata'
      AND  t.value:"value"::STRING = 'Q191'
    LIMIT 1
), candidate_polys AS (                        -- polys inside Estonia, w/o wikidata
    SELECT DISTINCT
           pf."osm_way_id" ,
           TO_GEOGRAPHY(pf."geometry")                         AS geo ,
           MAX(IFF(t.value:"key"::STRING = 'name',
                   t.value:"value"::STRING , NULL))
             OVER (PARTITION BY pf."osm_way_id")               AS name
    FROM   GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES pf ,
           estonia ,
           LATERAL FLATTEN(input => pf."all_tags")             t
    WHERE  pf."feature_type" = 'multipolygons'
      AND  ST_INTERSECTS(estonia.geo , TO_GEOGRAPHY(pf."geometry"))
    QUALIFY SUM(IFF(t.value:"key"::STRING = 'wikidata',1,0))
              OVER (PARTITION BY pf."osm_way_id") = 0
), poly_point_counts AS (                     -- count enclosed points for each poly
    SELECT  c."osm_way_id",
            COALESCE(c.name,'(no name)')      AS poly_name,
            COUNT(*)                          AS point_cnt,
            ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS rn
    FROM    candidate_polys                                   c
    JOIN    GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES_POINTS p
              ON  p."geometry" IS NOT NULL
             AND ST_CONTAINS(c.geo , TO_GEOGRAPHY(p."geometry"))
    GROUP BY c."osm_way_id", poly_name
)
SELECT  poly_name               AS name,
        point_cnt               AS contained_point_count
FROM    poly_point_counts
WHERE   rn <= 2
ORDER BY point_cnt DESC NULLS LAST;