/* Count distinct unordered pairs of California roads that
     • are tagged highway = motorway|trunk|primary|secondary|residential
     • lie (at least partly) in California
     • intersect each other spatially
     • have NO common node
     • are NOT tagged as bridges
*/

WITH ca AS (
    SELECT TO_GEOGRAPHY("state_geom") AS ca_geo
    FROM   GEO_OPENSTREETMAP_BOUNDARIES.GEO_US_BOUNDARIES."STATES"
    WHERE  "state" = 'CA'
),

roads AS (
    /* Build a list of qualified ways and their node-id arrays */
    SELECT
        pw."id",
        pw."geometry",
        ARRAY_AGG(DISTINCT n.value:"id"::NUMBER)      AS node_ids
    FROM   GEO_OPENSTREETMAP_BOUNDARIES.GEO_OPENSTREETMAP."PLANET_WAYS" pw
           ,LATERAL FLATTEN( INPUT => pw."all_tags"::VARIANT ) tag          -- inspect tags
           ,LATERAL FLATTEN( INPUT => pw."nodes"      )           n         -- collect node ids
           ,ca
    WHERE  tag.value:"key"::STRING  = 'highway'
      AND  LOWER(tag.value:"value"::STRING)
              IN ('motorway','trunk','primary','secondary','residential')
      AND  pw."all_tags" NOT ILIKE '%"bridge"%'
      AND  ST_INTERSECTS( TO_GEOGRAPHY(pw."geometry"), ca.ca_geo )
    GROUP BY pw."id", pw."geometry"
),

pair_candidates AS (
    /* Intersecting pairs that do not share any node */
    SELECT
        w1."id" AS way_id_1,
        w2."id" AS way_id_2
    FROM   roads w1
    JOIN   roads w2
           ON w1."id" < w2."id"   -- unordered pairs
          AND ST_INTERSECTS(
                 TO_GEOGRAPHY(w1."geometry"),
                 TO_GEOGRAPHY(w2."geometry")
              )
    WHERE  ARRAY_SIZE(
              ARRAY_INTERSECTION( w1.node_ids , w2.node_ids )
           ) = 0
)

SELECT COUNT(*) AS overlapping_road_pairs_without_shared_nodes
FROM   pair_candidates;