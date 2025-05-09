/* ============================================================
   Count overlapping (intersecting) pairs of California roads
   (motorway | trunk | primary | secondary | residential)
   that are NOT tagged as bridges and share NO common node.
   ============================================================ */

WITH ca_state AS (       -- California polygon
    SELECT  "state_geom"
    FROM    GEO_OPENSTREETMAP_BOUNDARIES.GEO_US_BOUNDARIES."STATES"
    WHERE   "state_name" = 'California'
),

/* -----------------------------------------------------------
   1)  Roads of interest inside California, excluding bridges
   ----------------------------------------------------------- */
eligible_ways AS (
    SELECT
        w."id",
        w."geometry"
    FROM (
        SELECT
            pw."id",
            pw."geometry",
            MAX(CASE WHEN f.value:"key" = 'highway'
                     THEN f.value:"value"::STRING END)  AS highway,
            MAX(CASE WHEN f.value:"key" = 'bridge'
                     THEN f.value:"value"::STRING END)  AS bridge
        FROM GEO_OPENSTREETMAP_BOUNDARIES.GEO_OPENSTREETMAP."PLANET_WAYS"  pw,
             LATERAL FLATTEN(INPUT => pw."all_tags") f
        GROUP BY pw."id", pw."geometry"
    ) w
    CROSS JOIN ca_state cs
    WHERE w."geometry" IS NOT NULL
      AND w.highway IN ('motorway','trunk','primary','secondary','residential')
      AND w.bridge  IS NULL
      AND ST_INTERSECTS(
            TO_GEOGRAPHY(w."geometry"),
            TO_GEOGRAPHY(cs."state_geom")
          )
),

/* -----------------------------------------------------------
   2)  Attach each way’s set of distinct node-ids
   ----------------------------------------------------------- */
way_with_nodes AS (
    SELECT
        ew."id",
        ew."geometry",
        ARRAY_AGG(DISTINCT n.value:"id"::NUMBER) AS node_ids
    FROM  eligible_ways                                                      ew
          JOIN GEO_OPENSTREETMAP_BOUNDARIES.GEO_OPENSTREETMAP."PLANET_WAYS" pw
                ON pw."id" = ew."id"
          ,   LATERAL FLATTEN(INPUT => pw."nodes") n
    GROUP BY ew."id", ew."geometry"
)

/* -----------------------------------------------------------
   3)  Count unordered pairs that intersect spatially
       AND have no shared nodes
   ----------------------------------------------------------- */
SELECT COUNT(*) AS overlapping_road_pairs
FROM   way_with_nodes  a
JOIN   way_with_nodes  b
       ON a."id" <  b."id"                                   -- each pair once
      AND ST_INTERSECTS(
            TO_GEOGRAPHY(a."geometry"),
            TO_GEOGRAPHY(b."geometry")
          )
      AND ARRAY_SIZE( ARRAY_INTERSECTION(a.node_ids, b.node_ids) ) = 0;