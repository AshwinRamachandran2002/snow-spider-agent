/* 2 Armenian multipolygons (without their own wikidata tag)
   that contain the greatest number of point‑features          */
WITH armenia AS (   ---------------------------------------------------
    /* geometry of the multipolygon whose wikidata = Q191 (Armenia) */
    SELECT TO_GEOGRAPHY(pf."geometry") AS geom
    FROM  GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES pf ,
          LATERAL FLATTEN (INPUT => pf."all_tags") tag
    WHERE pf."feature_type"            = 'multipolygons'
      AND tag.value:"key" ::STRING     = 'wikidata'
      AND tag.value:"value"::STRING    = 'Q191'
    LIMIT 1
),

polys_raw AS (   ------------------------------------------------------
    /* all multipolygons located inside Armenia together with tags     */
    SELECT
        COALESCE(pf."osm_way_id", pf."osm_id")         AS poly_id,
        TO_GEOGRAPHY(pf."geometry")                    AS geom,
        tag.value:"key"   ::STRING                     AS tag_key,
        tag.value:"value" ::STRING                     AS tag_val
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES pf ,
         LATERAL FLATTEN (INPUT => pf."all_tags") tag
    WHERE pf."feature_type" = 'multipolygons'
      AND ST_WITHIN( TO_GEOGRAPHY(pf."geometry"),
                     ( SELECT geom FROM armenia ) )
),

candidate_polys AS (   -----------------------------------------------
    /* keep only those without a wikidata tag; pull a name if present  */
    SELECT DISTINCT
           poly_id,
           geom,
           COALESCE(
               MAX(CASE WHEN tag_key = 'name' THEN tag_val END)
                   OVER (PARTITION BY poly_id),
               '<no name>' )                               AS name
    FROM polys_raw
    QUALIFY
        MAX(CASE WHEN tag_key = 'wikidata' THEN 1 ELSE 0 END)
            OVER (PARTITION BY poly_id) = 0
),

points AS (   ---------------------------------------------------------
    SELECT TO_GEOGRAPHY("geometry") AS geom
    FROM   GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES_POINTS
    WHERE  "geometry" IS NOT NULL
)

SELECT
       name                         AS multipolygon_name,
       COUNT(*)                     AS point_count
FROM   candidate_polys   c
JOIN   points            p
       ON ST_WITHIN(p.geom , c.geom)
GROUP  BY multipolygon_name
ORDER  BY point_count DESC NULLS LAST,
          multipolygon_name
LIMIT  2;