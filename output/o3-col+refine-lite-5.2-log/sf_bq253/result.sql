WITH q1095_geom AS (         -- geometry of the multipolygon that owns wikidata = Q1095
    SELECT TO_GEOGRAPHY(pf."geometry") AS geom
    FROM   GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES  pf ,
           LATERAL FLATTEN ( INPUT => pf."all_tags" ) tag
    WHERE  tag.value:"key"::STRING   = 'wikidata'
      AND  tag.value:"value"::STRING = 'Q1095'
    LIMIT 1
),
bbox AS (                     -- its bounding box
    SELECT ST_ENVELOPE(geom) AS geom_bbox
    FROM   q1095_geom
),
candidate_relations AS (      -- relations that intersect the bbox, have a name, but no wikidata tag
    SELECT  r."id",
            MAX( CASE WHEN tag.value:"key"::STRING = 'name'
                       THEN tag.value:"value"::STRING END )                      AS rel_name,
            SUM( IFF( tag.value:"key"::STRING = 'wikidata' , 1 , 0) )            AS wikidata_tag_cnt,
            r."geometry"                                                         AS geom_bin
    FROM    GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_RELATIONS  r ,
            LATERAL FLATTEN ( INPUT => r."all_tags" ) tag ,
            bbox b
    WHERE   ST_INTERSECTS( TO_GEOGRAPHY(r."geometry") , b.geom_bbox )
    GROUP BY r."id" , r."geometry"
    HAVING  rel_name IS NOT NULL
       AND  wikidata_tag_cnt = 0               -- exclude relations that already have a wikidata tag
),
features_in_relation AS (     -- every planet_feature lying inside each candidate relation
    SELECT  cr."id"                                                      AS rel_id ,
            cr.rel_name ,
            COALESCE(pf."osm_way_id" , pf."osm_id")                      AS feat_id ,
            pf."all_tags"
    FROM    candidate_relations                cr
    JOIN    GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES  pf
           ON ST_INTERSECTS( TO_GEOGRAPHY(pf."geometry") ,
                             TO_GEOGRAPHY(cr.geom_bin) )
),
relation_stats AS (           -- how many features & does at least one carry a wikidata tag ?
    SELECT  rel_id ,
            rel_name ,
            COUNT( DISTINCT feat_id )                                             AS feature_cnt ,
            MAX( IFF( tag.value:"key"::STRING = 'wikidata' , 1 , 0) )              AS has_wikidata_inside
    FROM    features_in_relation fir ,
            LATERAL FLATTEN ( INPUT => fir."all_tags" ) tag
    GROUP BY rel_id , rel_name
),
ranked AS (                    -- rank by number of enclosed features
    SELECT  rel_name ,
            feature_cnt ,
            ROW_NUMBER() OVER ( ORDER BY feature_cnt DESC NULLS LAST , rel_name )  AS rn
    FROM    relation_stats
    WHERE   has_wikidata_inside = 1            -- keep only those that enclose at least one wikidata‑tagged feature
)
SELECT  rel_name AS "relation_name"
FROM    ranked
WHERE   rn = 1;