/*  Top-2 multipolygons whose centroid lies inside Estonia (Q191),
    have no 'wikidata' tag themselves, and contain the greatest number
    of PLANET_FEATURES_POINTS.  */
WITH estonia AS (      ------------------------------------------------- Estonia geometry
    SELECT TO_GEOGRAPHY(pf."geometry") AS geom
    FROM   GEO_OPENSTREETMAP.GEO_OPENSTREETMAP."PLANET_FEATURES"  pf,
           LATERAL FLATTEN(input => pf."all_tags") t
    WHERE  pf."feature_type"           = 'multipolygons'
      AND  t.value:"key"::STRING       = 'wikidata'
      AND  t.value:"value"::STRING     = 'Q191'
    LIMIT 1
),
poly_tags AS (         ------------------------------------------------- all multipolygons whose
    SELECT                                                   -- centroid is in Estonia
        pf."osm_way_id",
        pf."geometry"                     AS geom_bin,
        tag.value:"key"::STRING           AS tag_key,
        tag.value:"value"::STRING         AS tag_val
    FROM   GEO_OPENSTREETMAP.GEO_OPENSTREETMAP."PLANET_FEATURES"  pf,
           estonia,
           LATERAL FLATTEN(input => pf."all_tags", OUTER => TRUE) tag
    WHERE  pf."feature_type" = 'multipolygons'
      AND  pf."geometry" IS NOT NULL
      AND  ST_CONTAINS(estonia.geom ,
                       ST_CENTROID(TO_GEOGRAPHY(pf."geometry")))
),
candidates AS (        ------------------------------------------------- drop those with a wikidata tag
    SELECT
        "osm_way_id",
        MAX(CASE WHEN tag_key = 'name'     THEN tag_val END) AS name,
        MAX_BY(geom_bin,1)                                   AS geom_bin
    FROM   poly_tags
    GROUP  BY "osm_way_id"
    HAVING MAX(CASE WHEN tag_key = 'wikidata' THEN 1 ELSE 0 END) = 0
),
ranked AS (            ------------------------------------------------- count contained points
    SELECT
        c."osm_way_id",
        c.name,
        COUNT(pt."geometry") AS pts_inside
    FROM   candidates              c
    LEFT  JOIN GEO_OPENSTREETMAP.GEO_OPENSTREETMAP."PLANET_FEATURES_POINTS" pt
           ON pt."geometry" IS NOT NULL
          AND ST_CONTAINS( TO_GEOGRAPHY(c.geom_bin),
                           TO_GEOGRAPHY(pt."geometry") )
    GROUP BY c."osm_way_id", c.name
)
SELECT "osm_way_id",
       name,
       pts_inside
FROM   ranked
ORDER BY pts_inside DESC NULLS LAST
LIMIT 2;