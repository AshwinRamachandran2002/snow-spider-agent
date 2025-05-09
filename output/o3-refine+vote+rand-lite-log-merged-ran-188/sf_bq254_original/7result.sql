/* 1) multipolygon that carries wikidata = Q191
   2) every other multipolygon that lies inside that reference area
      and has NO wikidata tag
   3) count how many POINT features fall inside each such polygon
   4) return the two polygons with the largest counts (with their names)        */
WITH reference AS ( ----------------------------------------------------------
    SELECT TO_GEOGRAPHY(pf."geometry") AS ref_geom
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES pf ,
         LATERAL FLATTEN ( INPUT => pf."all_tags") t
    WHERE pf."feature_type" = 'multipolygons'
      AND t.value:"key"   = 'wikidata'
      AND t.value:"value" = 'Q191'
    LIMIT 1
), ---------------------------------------------------------------------------

polys_base AS (  -------------------------------------------------------------
    SELECT
        COALESCE(pf."osm_way_id", pf."osm_id") AS poly_id,
        TO_GEOGRAPHY(pf."geometry")            AS geom,
        pf."all_tags"                          AS tags
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES pf
    WHERE pf."feature_type" = 'multipolygons'
      AND pf."geometry" IS NOT NULL
), ---------------------------------------------------------------------------

polys_with_wikidata AS ( -----------------------------------------------------
    SELECT DISTINCT pb.poly_id
    FROM polys_base pb ,
         LATERAL FLATTEN ( INPUT => pb.tags ) t
    WHERE t.value:"key" = 'wikidata'
), ---------------------------------------------------------------------------

candidate_polygons AS ( ------------------------------------------------------
    SELECT pb.poly_id,
           pb.geom,
           pb.tags
    FROM polys_base pb ,
         reference r
    WHERE ST_WITHIN( pb.geom , r.ref_geom )
      AND pb.poly_id NOT IN ( SELECT poly_id FROM polys_with_wikidata )
), ---------------------------------------------------------------------------

points_per_poly AS ( ---------------------------------------------------------
    SELECT
        cp.poly_id,
        COUNT(*) AS pts_cnt
    FROM candidate_polygons cp
    JOIN GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES_POINTS pt
      ON pt."geometry" IS NOT NULL
     AND ST_WITHIN( TO_GEOGRAPHY(pt."geometry"), cp.geom )
    GROUP BY cp.poly_id
), ---------------------------------------------------------------------------

names AS ( -------------------------------------------------------------------
    SELECT
        cp.poly_id,
        COALESCE(
            MIN( IFF( f.value:"key" = 'name', f.value:"value", NULL ) ),
            'N/A'
        ) AS poly_name
    FROM candidate_polygons cp ,
         LATERAL FLATTEN ( INPUT => cp.tags , OUTER => TRUE ) f
    GROUP BY cp.poly_id
), ---------------------------------------------------------------------------

final AS ( -------------------------------------------------------------------
    SELECT
        pp.poly_id,
        n.poly_name,
        pp.pts_cnt
    FROM points_per_poly pp
    JOIN names n ON n.poly_id = pp.poly_id
) ---------------------------------------------------------------------------

SELECT
    poly_name AS "NAME",
    pts_cnt   AS "NUMBER_OF_POINTS"
FROM final
ORDER BY pts_cnt DESC NULLS LAST, poly_name
LIMIT 2;