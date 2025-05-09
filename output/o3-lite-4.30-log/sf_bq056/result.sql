WITH ca AS (   -- California geometry
    SELECT TO_GEOMETRY("state_geom") AS ca_geom
    FROM   "GEO_OPENSTREETMAP_BOUNDARIES"."GEO_US_BOUNDARIES"."STATES"
    WHERE  "state" = 'CA'
),
prep AS (      -- parse tags, flag highways & bridges
    SELECT
        w."id",
        TO_GEOMETRY(w."geometry")               AS geom,
        w."nodes",
        MAX(IFF(t.value:"key"::STRING = 'bridge', 1, 0))                                            AS has_bridge,
        MAX(IFF(t.value:"key"::STRING = 'highway'
                AND t.value:"value"::STRING IN ('motorway','trunk','primary','secondary','residential'),
                1, 0))                                                                              AS is_target
    FROM   "GEO_OPENSTREETMAP_BOUNDARIES"."GEO_OPENSTREETMAP"."PLANET_WAYS" w,
           LATERAL FLATTEN(input => w."all_tags") t
    GROUP  BY w."id", w."geometry", w."nodes"
),
filtered AS (  -- California roads we care about
    SELECT p."id", p.geom, p."nodes"
    FROM   prep p, ca
    WHERE  p.is_target = 1
      AND  p.has_bridge = 0
      AND  p.geom IS NOT NULL
      AND  ST_INTERSECTS(p.geom, ca.ca_geom)
),
pair_candidates AS (   -- overlapping geometry pairs
    SELECT
        f1."id" AS id1,
        f2."id" AS id2,
        ARRAY_INTERSECTION(
            COALESCE(f1."nodes", PARSE_JSON('[]')),
            COALESCE(f2."nodes", PARSE_JSON('[]'))
        ) AS common_nodes
    FROM   filtered f1
    JOIN   filtered f2
      ON   f1."id" < f2."id"
     AND   ST_INTERSECTS(f1.geom, f2.geom)
),
valid_pairs AS (       -- keep only pairs without shared nodes
    SELECT id1, id2
    FROM   pair_candidates
    WHERE  ARRAY_SIZE(common_nodes) = 0
)
SELECT COUNT(*) AS pair_count
FROM   valid_pairs;