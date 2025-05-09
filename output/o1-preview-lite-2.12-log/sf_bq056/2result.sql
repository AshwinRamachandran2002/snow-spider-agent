WITH california AS (
    SELECT ST_GEOGFROMWKB("state_geom") AS "geom"
    FROM "GEO_OPENSTREETMAP_BOUNDARIES"."GEO_US_BOUNDARIES"."STATES"
    WHERE "state_name" = 'California'
),
tags AS (
    SELECT t."id", t."nodes", t."geometry",
        MAX(CASE WHEN s.value:"key"::STRING = 'highway' THEN s.value:"value"::STRING END) AS "highway",
        MAX(CASE WHEN s.value:"key"::STRING = 'bridge' THEN s.value:"value"::STRING END) AS "bridge"
    FROM "GEO_OPENSTREETMAP_BOUNDARIES"."GEO_OPENSTREETMAP"."PLANET_WAYS" t,
         LATERAL FLATTEN(input => t."all_tags") s
    GROUP BY t."id", t."nodes", t."geometry"
),
tags_with_geom AS (
    SELECT t.*, ST_GEOGFROMWKB(t."geometry") AS "geom"
    FROM tags t
),
selected_ways AS (
    SELECT t."id", t."geom" AS "geometry", t."nodes"
    FROM tags_with_geom t
    CROSS JOIN california c
    WHERE t."highway" IN ('motorway', 'trunk', 'primary', 'secondary', 'residential')
      AND (t."bridge" IS NULL OR t."bridge" != 'yes')
      AND ST_INTERSECTS(t."geom", c."geom")
),
nodes_per_way AS (
    SELECT w."id" AS way_id, n.value:"id"::NUMBER AS node_id
    FROM selected_ways w,
         LATERAL FLATTEN(input => w."nodes") n
),
pairs AS (
    SELECT w1."id" AS way_id1, w2."id" AS way_id2
    FROM selected_ways w1
    JOIN selected_ways w2 ON w1."id" < w2."id"
    WHERE ST_INTERSECTS(w1."geometry", w2."geometry")
),
pairs_with_common_nodes AS (
    SELECT DISTINCT p.way_id1, p.way_id2
    FROM pairs p
    JOIN nodes_per_way np1 ON p.way_id1 = np1.way_id
    JOIN nodes_per_way np2 ON p.way_id2 = np2.way_id
    WHERE np1.node_id = np2.node_id
)
SELECT COUNT(*) AS number_of_pairs
FROM pairs p
LEFT JOIN pairs_with_common_nodes pc
  ON p.way_id1 = pc.way_id1 AND p.way_id2 = pc.way_id2
WHERE pc.way_id1 IS NULL;