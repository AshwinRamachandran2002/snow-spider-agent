/*  Number of distinct pairs of California roads    (motorway‑|trunk‑|primary‑|secondary‑|residential)
    whose geometries overlap, that have no bridge tag, and that share no common node                */

WITH ca_state AS (                                   /* California polygon */
    SELECT "state_geom" AS geom
    FROM   GEO_OPENSTREETMAP_BOUNDARIES.GEO_US_BOUNDARIES.STATES
    WHERE  "state" = 'CA'
),                                                   /* collect tags for each way once */
way_tags AS (
    SELECT  w."id",
            w."geometry",
            w."nodes",
            /* flags built with one pass over the tag array */
            MIN(
                CASE 
                   WHEN LOWER(t.value:key::TEXT) = 'highway'
                    AND LOWER(t.value:value::TEXT) IN
                       ('motorway','trunk','primary','secondary','residential')
                   THEN 1 
                END
            )             AS has_target_highway,
            MIN(
                CASE 
                   WHEN LOWER(t.value:key::TEXT) = 'bridge'
                   THEN 1 
                END
            )             AS has_bridge
    FROM   GEO_OPENSTREETMAP_BOUNDARIES.GEO_OPENSTREETMAP.PLANET_WAYS w ,
           LATERAL FLATTEN( INPUT => w."all_tags") t
    GROUP  BY w."id", w."geometry", w."nodes"
),
roads AS (                                           /* eligible roads inside CA */
    SELECT  wt."id",
            wt."geometry",
            wt."nodes"
    FROM    way_tags  wt ,
            ca_state  s
    WHERE   wt.has_target_highway = 1               -- correct highway class
        AND wt.has_bridge          IS NULL          -- no bridge tag
        AND wt."geometry" IS NOT NULL
        AND ST_INTERSECTS(
                TO_GEOMETRY(wt."geometry"),
                TO_GEOMETRY(s.geom)                 -- road lies in California
            )
),
road_nodes AS (                                      /* explode node lists     */
    SELECT  r."id"             AS road_id,
            n.value:id::NUMBER AS node_id
    FROM    roads r,
            LATERAL FLATTEN( INPUT => r."nodes") n
),
node_shared_pairs AS (                               /* pairs that DO share a node */
    SELECT DISTINCT
           n1.road_id  AS id1,
           n2.road_id  AS id2
    FROM   road_nodes n1
    JOIN   road_nodes n2
           ON n1.node_id = n2.node_id
          AND n1.road_id < n2.road_id                -- keep ordering
)
SELECT COUNT(*) AS overlapping_pairs
FROM   roads r1
JOIN   roads r2
       ON r1."id" < r2."id"                          -- unique unordered pair
      AND ST_INTERSECTS(
              TO_GEOMETRY(r1."geometry"),
              TO_GEOMETRY(r2."geometry")
          )                                          -- geometries overlap
LEFT  JOIN node_shared_pairs sp                      -- eliminate pairs sharing nodes
       ON r1."id" = sp.id1
      AND r2."id" = sp.id2
WHERE  sp.id1 IS NULL;                               -- retain only pairs with NO shared node