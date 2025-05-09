WITH ca_geom AS (  -------------------------------------------------------------
    -- California outline
    SELECT TO_GEOGRAPHY("state_geom") AS geom
    FROM   GEO_OPENSTREETMAP_BOUNDARIES.GEO_US_BOUNDARIES."STATES"
    WHERE  "state" = 'CA'
),
-- ----------------------------------------------------------------------------- 
--  One row per way with the tags of interest
-- -----------------------------------------------------------------------------
way_tags AS (
    SELECT  w."id",
            MAX(IFF(f.value:"key"::string = 'highway', f.value:"value"::string, NULL)) AS highway,
            MAX(IFF(f.value:"key"::string = 'bridge',  f.value:"value"::string, NULL)) AS bridge
    FROM GEO_OPENSTREETMAP_BOUNDARIES.GEO_OPENSTREETMAP."PLANET_WAYS" w,
         LATERAL FLATTEN(input => w."all_tags") f
    GROUP BY w."id"
),
-- ----------------------------------------------------------------------------- 
--  California roads of required classes, excluding bridge ways
-- -----------------------------------------------------------------------------
roads AS (
    SELECT  w."id",
            w."geometry",
            w."nodes"
    FROM    GEO_OPENSTREETMAP_BOUNDARIES.GEO_OPENSTREETMAP."PLANET_WAYS" w
    JOIN    way_tags t  ON t."id" = w."id"
    WHERE   LOWER(t.highway) IN ('motorway','trunk','primary','secondary','residential')
      AND  (t.bridge IS NULL OR t.bridge = '' OR LOWER(t.bridge) = 'no')
      AND   ST_INTERSECTS(
                TO_GEOGRAPHY(w."geometry"),
                (SELECT geom FROM ca_geom)
             )
),
-- ----------------------------------------------------------------------------- 
--  Candidate intersecting pairs of those roads
-- -----------------------------------------------------------------------------
pairs AS (
    SELECT  r1."id" AS id1,
            r2."id" AS id2
    FROM    roads r1
    JOIN    roads r2
           ON r1."id" < r2."id"
          AND ST_INTERSECTS(
                  TO_GEOGRAPHY(r1."geometry"),
                  TO_GEOGRAPHY(r2."geometry")
              )
),
-- ----------------------------------------------------------------------------- 
--  All (way_id , node_id) combinations
-- -----------------------------------------------------------------------------
road_nodes AS (
    SELECT  r."id"                                    AS way_id,
            n.value:"id"::NUMBER                      AS node_id
    FROM    roads r,
            LATERAL FLATTEN(input => r."nodes") n
),
-- ----------------------------------------------------------------------------- 
--  Pairs that do share at least one common node
-- -----------------------------------------------------------------------------
pairs_with_common_nodes AS (
    SELECT DISTINCT p.id1, p.id2
    FROM   pairs      p
    JOIN   road_nodes n1 ON n1.way_id = p.id1
    JOIN   road_nodes n2 ON n2.way_id = p.id2
    WHERE  n1.node_id = n2.node_id
)
-- ----------------------------------------------------------------------------- 
--  Final count: intersecting pairs that have NO common nodes
-- -----------------------------------------------------------------------------
SELECT COUNT(*) AS number_of_overlapping_road_pairs
FROM   pairs p
LEFT   JOIN pairs_with_common_nodes c
       ON  p.id1 = c.id1
       AND p.id2 = c.id2
WHERE  c.id1 IS NULL;