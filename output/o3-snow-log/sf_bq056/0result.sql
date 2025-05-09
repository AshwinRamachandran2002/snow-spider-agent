/*  Count unordered pairs of California roads (highway = motorway|trunk|primary|secondary|residential)
    that  (a) intersect geometrically,
    (b) share no common nodes and
    (c) have no tag whose key contains “bridge”.
*/
WITH ca_roads AS (   -- candidate roads in California
    SELECT 
        w."id",
        ST_GEOMFROMWKB(w."geometry")          AS geom,
        w."nodes"                             AS nodes
    FROM GEO_OPENSTREETMAP_BOUNDARIES.GEO_OPENSTREETMAP."PLANET_WAYS"  w
         , GEO_OPENSTREETMAP_BOUNDARIES.GEO_US_BOUNDARIES."STATES"      s
         , LATERAL FLATTEN( INPUT => w."all_tags")                      t
    WHERE s."state_name" = 'California'
      AND ST_INTERSECTS( ST_GEOMFROMWKB(w."geometry"),
                         ST_GEOMFROMWKB(s."state_geom") )
    GROUP BY w."id", w."geometry", w."nodes"
    HAVING  /* required highway class                                       */
            MAX( CASE 
                    WHEN t.value:"key"::STRING = 'highway' 
                    THEN t.value:"value"::STRING 
                  END
                ) IN ('motorway','trunk','primary','secondary','residential')
        AND /* exclude anything whose tag-key contains “bridge”             */
            MAX( CASE 
                    WHEN LOWER(t.value:"key"::STRING) LIKE '%bridge%' 
                    THEN 1 ELSE 0 
                  END ) = 0
),
ca_nodes AS (        -- explode node list for each way
    SELECT 
        cr."id"                      AS way_id,
        n.value:"id"::NUMBER         AS node_id
    FROM ca_roads cr,
         LATERAL FLATTEN( INPUT => cr.nodes ) n
),
geom_overlaps AS (   -- unordered pairs of ways whose geometries intersect
    SELECT 
        a."id" AS way_a,
        b."id" AS way_b
    FROM ca_roads a
    JOIN ca_roads b
      ON a."id" < b."id"
     AND ST_INTERSECTS(a.geom , b.geom)
),
disjoint_node_pairs AS (   -- retain only pairs with NO shared nodes
    SELECT 
        o.way_a,
        o.way_b
    FROM geom_overlaps o
    LEFT JOIN ca_nodes na 
           ON na.way_id = o.way_a
    LEFT JOIN ca_nodes nb 
           ON nb.way_id = o.way_b
          AND nb.node_id = na.node_id
    GROUP BY o.way_a, o.way_b
    HAVING COUNT(nb.node_id) = 0      -- no common node
)
SELECT COUNT(*) AS overlapping_pairs_without_shared_nodes
FROM   disjoint_node_pairs;