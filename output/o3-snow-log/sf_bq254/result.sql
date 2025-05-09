/* 1️⃣ bbox around the Q191 multipolygon */
WITH q191_bbox AS (       
    SELECT ST_ENVELOPE( ST_GEOGFROMWKB(pf."geometry") ) AS gbox
    FROM   GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES pf,
           LATERAL FLATTEN( INPUT => pf."all_tags") tag
    WHERE  pf."feature_type" = 'multipolygons'
      AND  tag.value:"key"::STRING  = 'wikidata'
      AND  tag.value:"value"::STRING = 'Q191'
    LIMIT 1
)
/* 2️⃣ multipolygons inside that bbox, but **without** a wikidata tag */
,candidate_polys AS (
    SELECT  pf."osm_way_id",
            pf."geometry"    AS geom_wkb,
            pf."all_tags",
            MAX( IFF(tag.value:"key"::STRING = 'wikidata',1,0) ) AS has_wikidata
    FROM    GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES pf,
            q191_bbox,
            LATERAL FLATTEN( INPUT => pf."all_tags") tag
    WHERE   pf."feature_type" = 'multipolygons'
      AND   ST_INTERSECTS( ST_GEOGFROMWKB(pf."geometry"), q191_bbox.gbox )
    GROUP BY pf."osm_way_id", pf."geometry", pf."all_tags"
    HAVING  has_wikidata = 0
)
/* 3️⃣ all points located in the same bbox */
,bbox_points AS (
    SELECT ST_GEOGFROMWKB(pp."geometry") AS pnt
    FROM   GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES_POINTS pp,
           q191_bbox
    WHERE  ST_INTERSECTS( ST_GEOGFROMWKB(pp."geometry"), q191_bbox.gbox )
)
/* 4️⃣ count how many of those points fall inside every candidate polygon */
,scored AS (
    SELECT  c."osm_way_id",
            c."all_tags",
            COUNT(*) AS point_cnt
    FROM    candidate_polys c
    JOIN    bbox_points  p
      ON    ST_CONTAINS( ST_GEOGFROMWKB(c.geom_wkb), p.pnt )
    GROUP  BY c."osm_way_id", c."all_tags"
    ORDER  BY point_cnt DESC NULLS LAST
    LIMIT  2          -- ← keep only the 2 highest-scoring polygons
)
/* 5️⃣ extract their “name” (if any) */
SELECT  s."osm_way_id",
        MAX( IFF(tag.value:"key"::STRING = 'name',
                 tag.value:"value"::STRING,
                 NULL) )                AS "name",
        s.point_cnt
FROM    scored  s,
        LATERAL FLATTEN( INPUT => s."all_tags") tag
GROUP  BY s."osm_way_id", s.point_cnt
ORDER BY s.point_cnt DESC NULLS LAST;