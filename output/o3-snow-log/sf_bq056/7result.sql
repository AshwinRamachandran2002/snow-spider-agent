/*  Count pairs of California roads (motorway|trunk|primary|secondary|residential)
    that
      • overlap spatially,
      • have no common node,
      • and have no “bridge” tag.
*/

WITH ca AS (                                        -- California polygon
    SELECT
        TO_GEOGRAPHY("state_geom") AS geom
    FROM GEO_OPENSTREETMAP_BOUNDARIES.GEO_US_BOUNDARIES."STATES"
    WHERE "state_fips_code" = '06'
),

roads AS (                                          -- CA roads of interest
    SELECT
        w."id",

        /* pull the two tags we care about */
        MAX( IFF(t.value:"key"::STRING = 'highway', t.value:"value"::STRING, NULL) ) AS highway,
        MAX( IFF(t.value:"key"::STRING = 'bridge',  t.value:"value"::STRING, NULL) ) AS bridge_tag,

        /* geometry and nodes */
        TO_GEOGRAPHY(w."geometry")                                  AS geom,
        ARRAY_AGG(n.value:"id"::NUMBER)                             AS node_ids            -- all node ids
    FROM GEO_OPENSTREETMAP_BOUNDARIES.GEO_OPENSTREETMAP."PLANET_WAYS"  w
         , LATERAL FLATTEN(input => w."all_tags")                    t
         , LATERAL FLATTEN(input => w."nodes")                       n
    GROUP BY w."id", w."geometry"
    HAVING   highway IN ('motorway','trunk','primary','secondary','residential')
         AND bridge_tag IS NULL
         AND geom IS NOT NULL
         AND ST_INTERSECTS( geom , (SELECT geom FROM ca) )           -- keep roads in CA
),

overlapping_pairs AS (                               -- overlapping & node-disjoint pairs
    SELECT
        a."id" AS way_a ,
        b."id" AS way_b
    FROM roads a
    JOIN roads b
          ON a."id" < b."id"                         -- unique ordering
         AND ST_INTERSECTS( a.geom , b.geom )        -- geometries overlap
         AND ARRAY_SIZE(                             --    …but share no nodes
                 ARRAY_INTERSECTION(a.node_ids, b.node_ids)
             ) = 0
)

SELECT
    COUNT(*) AS overlapping_non_bridge_pairs_in_CA
FROM overlapping_pairs;