/*  Count unordered pairs of California roads (motorway-/trunk-/primary-/secondary-/residential)
    that  (1) spatially overlap,
          (2) do NOT share any node,
          (3) have no bridge tag                                              */
WITH cal_ways AS (          -------------------------------------------------- qualifying ways
    SELECT  w."id" ,
            w."geometry" ,
            w."nodes"
    FROM    GEO_OPENSTREETMAP_BOUNDARIES.GEO_OPENSTREETMAP.PLANET_WAYS  w
          , GEO_OPENSTREETMAP_BOUNDARIES.GEO_US_BOUNDARIES.STATES        s
          , LATERAL FLATTEN( INPUT => w."all_tags" ) f
    WHERE   s."state" = 'CA'
      AND   ST_INTERSECTS(
              ST_GEOGFROMWKB( w."geometry" ),
              TO_GEOGRAPHY( s."state_geom" )
            )
    GROUP BY w."id" , w."geometry" , w."nodes"
    HAVING  MAX( CASE WHEN f.value:"key"::STRING = 'highway'
                      THEN f.value:"value"::STRING END )
               IN ( 'motorway','trunk','primary','secondary','residential')
       AND  MAX( CASE WHEN f.value:"key"::STRING = 'bridge' THEN 1 END ) IS NULL
),

nodes AS (                   -------------------------------------------------- each way’s nodes
    SELECT  cw."id"     AS way_id ,
            n.value:"id"::NUMBER AS node_id
    FROM    cal_ways cw ,
            LATERAL FLATTEN( INPUT => cw."nodes") n
),

cal_pairs AS (              -------------------------------------- pairs whose geometries overlap
    SELECT  a."id"  AS id_a ,
            b."id"  AS id_b
    FROM    cal_ways a
    JOIN    cal_ways b
           ON a."id" < b."id"
          AND ST_INTERSECTS(
                ST_GEOGFROMWKB(a."geometry"),
                ST_GEOGFROMWKB(b."geometry")
              )
),

common_node_pairs AS (      -------------------------------------- pairs sharing ≥1 common node
    SELECT DISTINCT
           na.way_id AS id_a ,
           nb.way_id AS id_b
    FROM   nodes na
    JOIN   nodes nb
           ON na.node_id = nb.node_id
          AND na.way_id <  nb.way_id
)

SELECT  COUNT(*)  AS overlapping_non_bridge_pairs
FROM    cal_pairs          p
LEFT    JOIN common_node_pairs c
          ON p.id_a = c.id_a
         AND p.id_b = c.id_b
WHERE   c.id_a IS NULL ;   ---------------------------------------- keep pairs with NO common node