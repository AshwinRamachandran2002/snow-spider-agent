/* 2 multipolygons (without a wikidata tag) that are located in Estonia
   and contain the highest amount of point‑features                      */

WITH estonia AS (             -- geometry of the relation whose wikidata = Q191 (Estonia)
    SELECT  TO_GEOGRAPHY("geometry") AS geom
    FROM    GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES pf ,
            LATERAL FLATTEN( INPUT => pf."all_tags") tag
    WHERE   pf."feature_type"      = 'multipolygons'
      AND   tag.value:key          = 'wikidata'
      AND   tag.value:value        = 'Q191'
    LIMIT 1
),

candidates AS (                -- multipolygons in / overlapping Estonia and lacking a wikidata tag
    SELECT  pf."osm_way_id"                 AS osm_way_id,
            pf."all_tags"                   AS all_tags,
            TO_GEOGRAPHY(pf."geometry")     AS geom
    FROM    GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES pf ,
            estonia e
    WHERE   pf."feature_type"   = 'multipolygons'
      AND   ST_INTERSECTS( TO_GEOGRAPHY(pf."geometry"), e.geom )
      AND   pf."all_tags"::STRING NOT ILIKE '%"wikidata"%'        -- no wikidata tag
),

points_est AS (                -- every point‑feature that lies inside Estonia
    SELECT  TO_GEOGRAPHY(pfp."geometry") AS geom_pt
    FROM    GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES_POINTS pfp ,
            estonia e
    WHERE   pfp."geometry" IS NOT NULL
      AND   ST_INTERSECTS( TO_GEOGRAPHY(pfp."geometry"), e.geom )
)

SELECT
       cand.osm_way_id,
       COALESCE(         -- extract first name value; fallback if absent
           REGEXP_SUBSTR( cand.all_tags::STRING ,
                           '"name"\s*:\s*"([^"]+)"' , 1 , 1 , 'e' , 1) ,
           '(no name)' )                              AS "name",
       COUNT(*)                                        AS points_inside
FROM   candidates      cand
JOIN   points_est      pt
     ON ST_CONTAINS( cand.geom , pt.geom_pt )
GROUP  BY cand.osm_way_id, cand.all_tags
ORDER  BY points_inside DESC NULLS LAST,
         cand.osm_way_id
LIMIT 2;