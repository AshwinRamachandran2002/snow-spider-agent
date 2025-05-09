/* top‑2 multipolygons that lie inside the Q191 area, have no own wikidata
   tag, and contain the most point‑features                                       */

WITH
/* ------------------------------------------------------------------ */
/* geometry of the multipolygon that has wikidata = 'Q191'            */
q191_geom AS (
    SELECT
        TO_GEOGRAPHY(pf."geometry") AS geom
    FROM  GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES  pf,
          LATERAL FLATTEN(INPUT => pf."all_tags")                         tag
    WHERE pf."feature_type"      = 'multipolygons'
      AND tag.value:key::string  = 'wikidata'
      AND tag.value:value::string = 'Q191'
    LIMIT 1
),

/* ------------------------------------------------------------------ */
/* prepare all multipolygons with their name and (possible) wikidata  */
multipolygons AS (
    SELECT
        pf."osm_way_id"                                            AS id,
        TO_GEOGRAPHY(pf."geometry")                                AS geom,
        MIN(CASE WHEN tag.value:key::string = 'name'
                 THEN tag.value:value::string END)                 AS name,
        MAX(CASE WHEN tag.value:key::string = 'wikidata'
                 THEN tag.value:value::string END)                 AS wikidata
    FROM  GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES pf
          LEFT JOIN LATERAL FLATTEN(INPUT => pf."all_tags") tag
    WHERE pf."feature_type" = 'multipolygons'
    GROUP BY id, pf."geometry"
),

/* ------------------------------------------------------------------ */
/* keep only multipolygons inside the Q191 geometry and without       */
/* their own wikidata tag                                             */
candidates AS (
    SELECT
        mp.geom,
        COALESCE(mp.name, '<no name>')  AS name
    FROM  multipolygons mp
          JOIN q191_geom q
            ON ST_WITHIN(mp.geom, q.geom)
    WHERE mp.wikidata IS NULL
),

/* ------------------------------------------------------------------ */
/* every point feature that carries a geometry                        */
points AS (
    SELECT TO_GEOGRAPHY("geometry") AS geom
    FROM   GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES_POINTS
    WHERE  "geometry" IS NOT NULL
)

/* ------------------------------------------------------------------ */
SELECT
       c.name                                AS "NAME",
       COUNT(*)                              AS "POINT_COUNT"
FROM   candidates c
       JOIN points  p
         ON ST_WITHIN(p.geom, c.geom)
GROUP  BY c.name
ORDER  BY "POINT_COUNT" DESC NULLS LAST,
          "NAME"        ASC
LIMIT  2;