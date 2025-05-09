/*  Count distinct pairs of California roads (motorway | trunk | primary | 
    secondary | residential) that  
      • intersect one another,
      • share NO common node IDs, and
      • have no “bridge” tag                                          */

WITH ca_state AS (                       -- California state outline
    SELECT TO_GEOGRAPHY("state_geom") AS geom
    FROM   GEO_OPENSTREETMAP_BOUNDARIES.GEO_US_BOUNDARIES."STATES"
    WHERE  "state" = 'CA'
), --------------------------------------------------------------------
candidates AS (                         -- qualifying road “ways” in CA
    SELECT  w."id",
            TO_GEOGRAPHY(w."geometry") AS geom,
            w."nodes"
    FROM    GEO_OPENSTREETMAP_BOUNDARIES.GEO_OPENSTREETMAP."PLANET_WAYS" w
            JOIN ca_state s
              ON  ST_INTERSECTS( TO_GEOGRAPHY(w."geometry"), s.geom )
            ,   LATERAL FLATTEN( INPUT => w."all_tags") tag
    GROUP BY w."id", w."geometry", w."nodes"
    HAVING  MAX( CASE
                   WHEN tag.value:"key"::STRING = 'highway'
                        AND tag.value:"value"::STRING IN
                            ('motorway','trunk','primary',
                             'secondary','residential')
                   THEN 1 ELSE 0 END ) = 1          -- has wanted highway tag
        AND MAX( CASE
                   WHEN tag.value:"key"::STRING = 'bridge' THEN 1 ELSE 0
                 END ) = 0                          -- no bridge tag
), --------------------------------------------------------------------
intersecting_pairs AS (                 -- pairs whose geometries overlap
    SELECT  c1."id"        AS road_id_1,
            c1."nodes"     AS nodes1,
            c2."id"        AS road_id_2,
            c2."nodes"     AS nodes2
    FROM    candidates c1
            JOIN candidates c2
              ON  c1."id" < c2."id"
              AND ST_INTERSECTS(c1.geom, c2.geom)
), --------------------------------------------------------------------
uniq_pairs AS (                         -- keep only pairs with ZERO shared nodes
    SELECT  p.road_id_1,
            p.road_id_2
    FROM    intersecting_pairs p,
            LATERAL FLATTEN( INPUT => p.nodes1 ) n1,
            LATERAL FLATTEN( INPUT => p.nodes2 ) n2
    GROUP BY p.road_id_1, p.road_id_2
    HAVING  MAX( CASE
                   WHEN n1.value:"id"::NUMBER = n2.value:"id"::NUMBER
                   THEN 1 ELSE 0 END ) = 0
) ---------------------------------------------------------------------
SELECT COUNT(*) AS total_overlapping_road_pairs_CA
FROM   uniq_pairs;