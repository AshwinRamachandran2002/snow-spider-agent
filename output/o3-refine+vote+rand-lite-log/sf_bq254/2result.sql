/*  Two multipolygons that
      • are located inside the polygon tagged wikidata = Q191,
      • have no own wikidata tag,
      • contain the greatest number of point‑features.                    */

WITH q191 AS (         -- geometry of the reference multipolygon
    SELECT
        TO_GEOGRAPHY(pf."geometry") AS geom
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP."PLANET_FEATURES"  pf,
         LATERAL FLATTEN(input => pf."all_tags") tag
    WHERE tag.value:key   = 'wikidata'
      AND tag.value:value = 'Q191'
      AND pf."feature_type" = 'multipolygons'
    LIMIT 1
),

poly_tags AS (         -- every tag of every multipolygon that lies inside Q191
    SELECT
        pf."osm_way_id"                                           AS poly_id,
        ST_ASWKT(TO_GEOGRAPHY(pf."geometry"))                     AS wkt_geom, -- text for GROUP BY
        f.value:key                                               AS tag_key,
        f.value:value                                             AS tag_val
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP."PLANET_FEATURES" pf,
         q191 q,
         LATERAL FLATTEN(input => pf."all_tags") f
    WHERE pf."feature_type" = 'multipolygons'
      AND ST_CONTAINS(q.geom , TO_GEOGRAPHY(pf."geometry"))
),

aggregated AS (        -- collect name and wikidata (if any) for each polygon
    SELECT
        poly_id,
        wkt_geom,
        MAX(CASE WHEN tag_key = 'name'     THEN tag_val END) AS poly_name,
        MAX(CASE WHEN tag_key = 'wikidata' THEN tag_val END) AS wikidata_tag
    FROM poly_tags
    GROUP BY poly_id, wkt_geom
),

candidate_polys AS (   -- keep only polygons without a wikidata tag
    SELECT
        poly_id,
        TO_GEOGRAPHY(wkt_geom)               AS geom,
        COALESCE(poly_name, 'Unnamed')       AS poly_name
    FROM aggregated
    WHERE wikidata_tag IS NULL
),

points AS (            -- all point‑type features that have valid geometry
    SELECT TO_GEOGRAPHY("geometry") AS geom
    FROM   GEO_OPENSTREETMAP.GEO_OPENSTREETMAP."PLANET_FEATURES_POINTS"
    WHERE  "geometry" IS NOT NULL
)

SELECT
       cp.poly_name            AS "NAME",
       COUNT(*)                AS "POINT_COUNT"
FROM   candidate_polys cp
JOIN   points p
       ON ST_CONTAINS(cp.geom , p.geom)        -- point lies inside polygon
GROUP  BY cp.poly_id, cp.poly_name
ORDER  BY "POINT_COUNT" DESC NULLS LAST,
          "NAME"
LIMIT  2;