/* 1.   geometry of Estonia (wikidata = Q191)                                   */
WITH estonia AS (       
    SELECT TO_GEOGRAPHY(p."geometry") AS geom
    FROM   GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES p ,
           TABLE(FLATTEN(INPUT => p."all_tags")) t
    WHERE  p."feature_type"      = 'multipolygons'
      AND  t.value:"key"::string = 'wikidata'
      AND  t.value:"value"::string = 'Q191'
    LIMIT 1
)
/* 2.   every multipolygon geometry (keep id once)                              */
, base_polys AS (      
    SELECT DISTINCT
           COALESCE("osm_way_id","osm_id")            AS poly_id ,
           TO_GEOGRAPHY("geometry")                   AS geom
    FROM   GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES
    WHERE  "feature_type" = 'multipolygons'
      AND  "geometry"     IS NOT NULL
)
/* 3.   flatten tags for those multipolygons                                    */
, poly_tags AS (     
    SELECT 
           COALESCE(p."osm_way_id",p."osm_id")        AS poly_id ,
           f.value:"key"::string                      AS tag_key ,
           f.value:"value"::string                    AS tag_val
    FROM   GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES p ,
           TABLE(FLATTEN(INPUT => p."all_tags")) f
    WHERE  p."feature_type" = 'multipolygons'
)
/* 4.   pivot out the tags we need (wikidata , name)                            */
, tag_pivot AS (    
    SELECT 
           poly_id ,
           MAX(CASE WHEN tag_key = 'wikidata' THEN tag_val END) AS wikidata ,
           MAX(CASE WHEN tag_key = 'name'     THEN tag_val END) AS name
    FROM   poly_tags
    GROUP  BY poly_id
)
/* 5.   candidate polygons : inside Estonia and without wikidata tag            */
, candidate_polys AS (  
    SELECT b.poly_id ,
           b.geom ,
           t.name
    FROM   base_polys  b
           LEFT JOIN tag_pivot t        ON b.poly_id = t.poly_id
           CROSS JOIN estonia  e
    WHERE  t.wikidata IS NULL
      AND  ST_WITHIN( b.geom , e.geom )
)
/* 6.   count how many points fall inside each candidate polygon                */
SELECT 
       c.poly_id ,
       c.name ,
       COUNT(*)                   AS points_inside
FROM   candidate_polys                           c
JOIN   GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES_POINTS pt
       ON pt."geometry" IS NOT NULL
      AND ST_CONTAINS( c.geom , TO_GEOGRAPHY(pt."geometry") )
GROUP  BY c.poly_id , c.name
ORDER  BY points_inside DESC NULLS LAST , c.poly_id
LIMIT  2;