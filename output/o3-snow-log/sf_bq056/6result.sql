/*  Count overlapping California road-way pairs that
    • have highway tag = motorway | trunk | primary | secondary | residential
    • have NO bridge tag
    • geometrically overlap
    • share ZERO common nodes                                       */

WITH ca_state AS (            -- California boundary
    SELECT ST_GeomFromWKB("state_geom") AS geom
    FROM   GEO_OPENSTREETMAP_BOUNDARIES.GEO_US_BOUNDARIES."STATES"
    WHERE  "state" = 'CA'
),

qualified AS (                -- OSM ways meeting tag + location rules
    SELECT
        w."id",
        ST_GeomFromWKB(MIN(w."geometry")) AS geom          -- one geometry per way
    FROM  GEO_OPENSTREETMAP_BOUNDARIES.GEO_OPENSTREETMAP."PLANET_WAYS"  w
          ,LATERAL FLATTEN(INPUT => w."all_tags")           f
          ,ca_state                                         s
    /* keep only ways whose geometry intersects California */
    WHERE ST_Intersects( ST_GeomFromWKB(w."geometry"), s.geom )
    GROUP BY w."id"
    HAVING
           /* at least one desired highway tag */
           MAX(
               CASE
                   WHEN f.value:"key"::STRING = 'highway'
                    AND f.value:"value"::STRING IN
                        ('motorway','trunk','primary','secondary','residential')
                   THEN 1 ELSE 0
               END
           ) = 1
       AND /* NO bridge tag at all */
           MAX(
               CASE
                   WHEN f.value:"key"::STRING = 'bridge' THEN 1 ELSE 0
               END
           ) = 0
),

way_nodes AS (                -- array of node-ids per qualified way
    SELECT
        w."id",
        ARRAY_AGG(n.value:"id"::NUMBER) AS nodes_arr
    FROM  GEO_OPENSTREETMAP_BOUNDARIES.GEO_OPENSTREETMAP."PLANET_WAYS" w,
          LATERAL FLATTEN(INPUT => w."nodes") n
    WHERE w."id" IN (SELECT "id" FROM qualified)
    GROUP BY w."id"
),

overlap_pairs AS (            -- overlapping pairs with no shared nodes
    SELECT
        a."id" AS way_id_a,
        b."id" AS way_id_b
    FROM   qualified a
    JOIN   qualified b  ON a."id" < b."id"
                       AND ST_Intersects(a.geom, b.geom)
    JOIN   way_nodes  na ON na."id" = a."id"
    JOIN   way_nodes  nb ON nb."id" = b."id"
    WHERE  ARRAY_SIZE(ARRAY_INTERSECTION(na.nodes_arr, nb.nodes_arr)) = 0
)

SELECT COUNT(*) AS overlapping_pairs_without_shared_nodes
FROM   overlap_pairs;