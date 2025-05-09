WITH california AS (
    SELECT ST_GEOMFROMWKB("state_geom", 4326) AS "state_geom"
    FROM GEO_OPENSTREETMAP_BOUNDARIES.GEO_US_BOUNDARIES.STATES
    WHERE "state_name" = 'California'
),
ways_with_tags AS (
    SELECT t."id", t."geometry", t."nodes",
        OBJECT_AGG(tag.value:"key"::VARCHAR, tag.value:"value") AS "tags"
    FROM GEO_OPENSTREETMAP_BOUNDARIES.GEO_OPENSTREETMAP.PLANET_WAYS t,
         LATERAL FLATTEN(input => t."all_tags") tag
    GROUP BY t."id", t."geometry", t."nodes"
),
filtered_ways AS (
    SELECT w."id", w."geometry", w."nodes"
    FROM ways_with_tags w, california
    WHERE w."tags":highway::STRING IN ('motorway', 'trunk', 'primary', 'secondary', 'residential')
      AND w."tags":bridge IS NULL
      AND ST_INTERSECTS(
            ST_GEOMFROMWKB(w."geometry", 4326), 
            california."state_geom"
          )
),
pairs AS (
    SELECT w1."id" AS "id1", w2."id" AS "id2"
    FROM filtered_ways w1
    JOIN filtered_ways w2 ON w1."id" < w2."id"
    WHERE ST_INTERSECTS(
        ST_GEOMFROMWKB(w1."geometry", 4326), 
        ST_GEOMFROMWKB(w2."geometry", 4326)
        )
),
nodes_per_way AS (
    SELECT w."id" AS "way_id", n.value:"id"::NUMBER AS "node_id"
    FROM filtered_ways w,
    LATERAL FLATTEN(input => w."nodes") n
),
shared_nodes_pairs AS (
    SELECT DISTINCT n1."way_id" AS "id1", n2."way_id" AS "id2"
    FROM nodes_per_way n1
    JOIN nodes_per_way n2 ON n1."node_id" = n2."node_id" AND n1."way_id" < n2."way_id"
),
non_overlapping_pairs AS (
    SELECT p."id1", p."id2"
    FROM pairs p
    LEFT JOIN shared_nodes_pairs s ON p."id1" = s."id1" AND p."id2" = s."id2"
    WHERE s."id1" IS NULL
)
SELECT COUNT(*) AS "number_of_pairs"
FROM non_overlapping_pairs;