/*  Count pairs of California motorway / trunk / primary / secondary /
    residential ways whose geometries overlap, share no common node,
    and where neither way has bridge = yes                                  */
WITH ca AS (           ------------------------------------------------------
    /* California state geometry */
    SELECT  "state_geom"
    FROM    GEO_OPENSTREETMAP_BOUNDARIES.GEO_US_BOUNDARIES."STATES"
    WHERE   "state" = 'CA'
), bridge_ways AS (    ------------------------------------------------------
    /* Ways that carry bridge = yes (to be excluded later) */
    SELECT DISTINCT w."id"
    FROM   GEO_OPENSTREETMAP_BOUNDARIES.GEO_OPENSTREETMAP."PLANET_WAYS" w,
           LATERAL FLATTEN (INPUT => w."all_tags") t
    WHERE  t.value:"key"::STRING   = 'bridge'
      AND  t.value:"value"::STRING = 'yes'
), filtered_ways AS (  ------------------------------------------------------
    /* California roads of the requested classes, visible, not bridges     */
    SELECT  DISTINCT
            w."id",
            w."geometry",
            w."nodes"
    FROM    GEO_OPENSTREETMAP_BOUNDARIES.GEO_OPENSTREETMAP."PLANET_WAYS" w
            CROSS JOIN ca
            , LATERAL FLATTEN (INPUT => w."all_tags") tag
    WHERE   w."visible" = TRUE
      AND   tag.value:"key"::STRING  = 'highway'
      AND   tag.value:"value"::STRING IN
            ('motorway','trunk','primary','secondary','residential')
      AND   ST_INTERSECTS(
                TO_GEOGRAPHY(w."geometry"),
                TO_GEOGRAPHY(ca."state_geom")
            )
      AND   w."id" NOT IN (SELECT "id" FROM bridge_ways)
), way_nodes AS (      ------------------------------------------------------
    /* Expand nodes for each remaining way                                 */
    SELECT  fw."id"                    AS way_id,
            n.value:"id"::NUMBER       AS node_id
    FROM    filtered_ways  fw,
            LATERAL FLATTEN (INPUT => fw."nodes") n
), candidate_pairs AS ( ------------------------------------------------------
    /* Overlapping-geometry way pairs                                       */
    SELECT  w1."id" AS way1,
            w2."id" AS way2
    FROM    filtered_ways w1
            JOIN filtered_ways w2
                 ON w1."id" < w2."id"      -- unique unordered pair
                AND ST_INTERSECTS(
                        TO_GEOGRAPHY(w1."geometry"),
                        TO_GEOGRAPHY(w2."geometry")
                    )
)
SELECT COUNT(*) AS "overlapping_pairs_without_shared_nodes"
FROM   candidate_pairs p
WHERE  NOT EXISTS (                 -- ensure no shared node
           SELECT 1
           FROM   way_nodes n1
                  JOIN way_nodes n2
                    ON n1.node_id = n2.node_id
           WHERE  n1.way_id = p.way1
             AND  n2.way_id = p.way2
       );