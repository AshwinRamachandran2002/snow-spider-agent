WITH ca AS (  ----------------------------------------------------
             --  California boundary as GEOGRAPHY (single row)
             ----------------------------------------------------
    SELECT TO_GEOGRAPHY("state_geom") AS geom
    FROM   GEO_OPENSTREETMAP_BOUNDARIES.GEO_US_BOUNDARIES.STATES
    WHERE  "state_fips_code" = '06'
),

tags AS ( ---------------------------------------------------------
            -- explode all_tags once, keep the useful pieces
            ---------------------------------------------------------
    SELECT
        w."id"                        AS way_id,
        t.value:"key"::STRING   AS tag_key ,
        t.value:"value"::STRING AS tag_val
    FROM GEO_OPENSTREETMAP_BOUNDARIES.GEO_OPENSTREETMAP.PLANET_WAYS w ,
         LATERAL FLATTEN(INPUT => w."all_tags") t
),

roads AS ( --------------------------------------------------------
            -- wanted highway classes, no bridge tag, in California
            --------------------------------------------------------
    SELECT
        w."id"                     AS road_id,
        TO_GEOGRAPHY(w."geometry") AS geom,
        w."nodes"                  AS nodes
    FROM   GEO_OPENSTREETMAP_BOUNDARIES.GEO_OPENSTREETMAP.PLANET_WAYS w
           /* join to tags twice: one for highway, one for bridge   */
    INNER  JOIN tags h          ON w."id" = h.way_id
    LEFT   JOIN tags b          ON w."id" = b.way_id
                                AND b.tag_key = 'bridge'
    CROSS  JOIN ca
    WHERE  h.tag_key = 'highway'
      AND  h.tag_val IN ('motorway','trunk','primary','secondary','residential')
      AND  b.way_id IS NULL                       -- no bridge tag
      AND  ST_INTERSECTS( TO_GEOGRAPHY(w."geometry") , ca.geom )
),

road_nodes AS ( ---------------------------------------------------
                 -- one row per (road , node_id)
                 ---------------------------------------------------
    SELECT
        r.road_id,
        n.value:"id"::NUMBER AS node_id
    FROM roads r ,
         LATERAL FLATTEN(INPUT => r.nodes) n
),

shared_pairs AS ( -------------------------------------------------
                  -- road-pairs sharing ≥1 node
                  -------------------------------------------------
    SELECT DISTINCT
           LEAST(r1.road_id , r2.road_id)  AS id1 ,
           GREATEST(r1.road_id, r2.road_id) AS id2
    FROM road_nodes r1
    JOIN road_nodes r2
          ON r1.node_id = r2.node_id
         AND r1.road_id < r2.road_id
),

candidate_pairs AS ( ---------------------------------------------
                     -- unordered pairs whose geometries overlap
                     ------------------------------------------------
    SELECT
        r1.road_id AS id1 ,
        r2.road_id AS id2
    FROM roads r1
    JOIN roads r2
          ON r1.road_id < r2.road_id
         AND ST_INTERSECTS(r1.geom , r2.geom)
)

/* final answer ---------------------------------------------------*/
SELECT COUNT(*)              AS overlapping_non_node_sharing_pairs
FROM   candidate_pairs  cp
LEFT   JOIN shared_pairs sp
       ON  sp.id1 = cp.id1
       AND sp.id2 = cp.id2
WHERE  sp.id1 IS NULL;